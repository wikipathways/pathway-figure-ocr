#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import json
import psycopg2
import psycopg2.extras
import re
import transforms

def match(args):
    transformations = []
    for arg in args:
        name = arg["name"]
        transform = getattr(getattr(transforms, name), name)
        transformations.append({"transform": transform, "name": name, "category": arg["category"]})

    normalizations = []
    for t in transformations:
        t_category = t["category"]
        if t_category == "normalize":
            normalizations.append(t)

    conn = psycopg2.connect("dbname=pfocr")
    ocr_processors__figures_cur = conn.cursor(cursor_factory=psycopg2.extras.DictCursor)
    symbols_cur = conn.cursor(cursor_factory=psycopg2.extras.DictCursor)
    words_cur = conn.cursor(cursor_factory=psycopg2.extras.DictCursor)
    ocr_processors__figures__words_cur = conn.cursor(cursor_factory=psycopg2.extras.DictCursor)

    try:
        ocr_results_query = '''
        /* This query might seem as if it could be simpler, but we have to account
           for the case of a result with just one textAnnotation. The extra
           complexity of this query is to ensure we don't exclude
           the description for such a lone textAnnotation. */
        WITH descriptions AS (
                SELECT ocr_processor_id, figure_id, jsonb_extract_path(jsonb_array_elements(jsonb_extract_path(result, 'textAnnotations')), 'description') AS description
                FROM ocr_processors__figures
        ),
        first_descriptions AS (
                SELECT jsonb_extract_path(result, 'textAnnotations', '0', 'description') AS first_description
                FROM ocr_processors__figures
                WHERE jsonb_array_length(jsonb_extract_path(result, 'textAnnotations')) > 1
        )
        SELECT DISTINCT ocr_processor_id, figure_id, description
        FROM descriptions
        LEFT JOIN first_descriptions
        ON descriptions.description = first_descriptions.first_description
        WHERE first_descriptions.first_description IS NULL;
        '''
        ocr_processors__figures_cur.execute(ocr_results_query)

        symbols_query = '''
        SELECT id, symbol
        FROM symbols;
        '''
        symbols_cur.execute(symbols_query)

        # original symbol incl/
        symbol_ids_by_symbol = {}
        for s in symbols_cur:
            symbol_id = s["id"]
            symbol = s["symbol"]
            normalized_results = [symbol]
            for normalization in normalizations:
                for normalized in normalized_results:
                    normalized_results = []
                    for n in normalization["transform"](normalized):
                        normalized_results.append(n)
                        if n not in symbol_ids_by_symbol: 
                            symbol_ids_by_symbol[n] = symbol_id
                        # Also collect unique uppercased symbols for matching
                        if n.upper() not in symbol_ids_by_symbol:
                            symbol_ids_by_symbol[n.upper] = symbol_id

        #with open("./symbol_ids_by_symbol.json", "a+") as symbol_ids_by_symbol_file:
        #    symbol_ids_by_symbol_file.write(json.dumps(symbol_ids_by_symbol))

        word_ids_by_transformed_word = {}
        words_cur.execute(
            '''
            SELECT id, word
            FROM words;
            '''
        )
        for w in words_cur:
            word_id = w["id"]
            word = w["word"]
            word_ids_by_transformed_word[word] = word_id

        successes = []
        fails = []
        #print('SUCCESSES: found matches for the following')
        for row in ocr_processors__figures_cur:
            ocr_processor_id = row["ocr_processor_id"]
            figure_id = row["figure_id"]
            word = row["description"]

            transformed_words = [word]
            transforms_applied = []

            matches = []
            for transformation in transformations:
                transforms_applied.append(transformation["name"])
                for transformed_word_orig in transformed_words:
                    transformed_words = []
                    for transformed_word in transformation["transform"](transformed_word_orig):
			# perform match for original and uppercased words (see elif)
                        if transformed_word in symbol_ids_by_symbol: 
                            matches.append(transformed_word)
                            word_id = ""
                            if transformed_word not in word_ids_by_transformed_word: 
                                # This might not be the best way to insert. TODO: look at the proper way to handle this.
                                words_cur.execute(
                                    '''
                                    INSERT INTO words (word)
                                    VALUES (%s)
                                    ON CONFLICT (word) DO UPDATE SET word = EXCLUDED.word
                                    RETURNING id;
                                    ''',
                                    (transformed_word, )
                                )
                                word_id = words_cur.fetchone()[0]
                                word_ids_by_transformed_word[transformed_word] = word_id
                            else:
                                word_id = word_ids_by_transformed_word[transformed_word]
                            if word_id:
                                transform_names = []
                                for t in args[0:len(transforms_applied)]:
                                    transform_names.append(t["name"])

                                ocr_processors__figures__words_cur.execute('''
                                    INSERT INTO ocr_processors__figures__words (ocr_processor_id, figure_id, word_id, transforms)
                                    VALUES (%s, %s, %s, %s)
                                    ON CONFLICT DO NOTHING;
                                    ''',
                                    (ocr_processor_id, figure_id, word_id, json.dumps(transform_names))
                                )
                        elif transformed_word.upper() in symbol_ids_by_symbol:
                            transformed_word = transformed_word.upper()
                            matches.append(transformed_word)
                            word_id = ""
                            if transformed_word not in word_ids_by_transformed_word:
                                # This might not be the best way to insert. TODO: look at the proper way to handle this.
                                words_cur.execute(
                                    '''
                                    INSERT INTO words (word)
                                    VALUES (%s)
                                    ON CONFLICT (word) DO UPDATE SET word = EXCLUDED.word
                                    RETURNING id;
                                    ''',
                                    (transformed_word, )
                                )
                                word_id = words_cur.fetchone()[0]
                                word_ids_by_transformed_word[transformed_word] = word_id
                            else:
                                word_id = word_ids_by_transformed_word[transformed_word]
                            if word_id:
                                transform_names = []
                                for t in args[0:len(transforms_applied)]:
                                    transform_names.append(t["name"])

                                ocr_processors__figures__words_cur.execute('''
                                    INSERT INTO ocr_processors__figures__words (ocr_processor_id, figure_id, word_id, transforms)
                                    VALUES (%s, %s, %s, %s)
                                    ON CONFLICT DO NOTHING;
                                    ''',
                                    (ocr_processor_id, figure_id, word_id, json.dumps(transform_names))
                                )
                        else:
                            transformed_words.append(transformed_word)

            if len(matches) > 0:
                successes.append(word + ' => ' + ' & '.join(matches))
            else:
                fails.append(word)

        conn.commit()

        #print('FAILS: could not find matches for the following')
        with open("./successes.txt", "a+") as successesfile:
            successesfile.write('\t\n\t'.join(successes))

        with open("./fails.txt", "a+") as failsfile:
            failsfile.write('\t\n\t'.join(fails))

        print('match: SUCCESS')

    except(psycopg2.DatabaseError) as e:
        print('Error %s' % psycopg2.DatabaseError)
        print('Error %s' % e)
        sys.exit(1)
        
    finally:
        if conn:
            conn.close()
