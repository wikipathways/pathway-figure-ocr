#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import json
import psycopg2
import psycopg2.extras
import re
import transforms

def match(args):
    transformations = []
    for a in args:
        name = a["name"]
        transform = getattr(getattr(transforms, name), name)
        transformations.append({"transform": transform, "name": name, "category": a["category"]})

    normalizations = []
    for t in transformations:
        t_category = t["category"]
        if t_category == "normalize":
            normalizations.append(t)

#    normalization_args = getattr(args, "normalize")
#    # TODO should we apply noop automatically?
#    #normalizations = [{"transform": transforms.noop.noop, "name": "noop"}]
#    normalizations = []
#    for n in normalization_args:
#        normalize = getattr(getattr(transforms, n), n)
#        normalizations.append({"transform": normalize, "name": n})
#
#    mutation_args = getattr(args, "mutate")
#    mutations = []
#    for m in mutation_args:
#        mutate = getattr(getattr(transforms, m), m)
#        mutations.append({"transform": mutate, "name": m})
#    transformations = normalizations + mutations

    conn = psycopg2.connect("dbname=pfocr")
    ocr_processors__figures_cur = conn.cursor(cursor_factory=psycopg2.extras.DictCursor)
    symbols_cur = conn.cursor(cursor_factory=psycopg2.extras.DictCursor)
    words_cur = conn.cursor()
    ocr_processors__figures__words_cur = conn.cursor(cursor_factory=psycopg2.extras.DictCursor)

    try:
        ocr_processors__figures__words_cur.execute("DELETE FROM ocr_processors__figures__words;")
        words_cur.execute("DELETE FROM words;")

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

        ocr_processor__figure__word_rows = ocr_processors__figures_cur.fetchall()

        symbols_query = '''
        SELECT id, symbol
        FROM symbols;
        '''
        symbols_cur.execute(symbols_query)
        symbol_rows = symbols_cur.fetchall()

        # original symbol incl/ due to noop
        symbol_ids_by_symbol = {}
        for s in symbol_rows:
            symbol_id = s[0]
            symbol = s[1]
            normalized_results = [symbol]
            for normalization in normalizations:
                for normalized in normalized_results:
                    normalized_results = []
                    for n in normalization["transform"](normalized):
                        normalized_results.append(n)
                        if n not in symbol_ids_by_symbol: 
                            symbol_ids_by_symbol[n] = symbol_id

        word_ids_by_transformed_word = {}
        fails = []
        print('SUCCESSES: found matches for the following')
        for row in ocr_processor__figure__word_rows:
            ocr_processor_id = row[0]
            figure_id = row[1]
            word = row[2]

            transformed_words = [word]
            transforms_applied = []

            matches = []
            for transformation in transformations:
                transforms_applied.append(transformation["name"])
                for transformed_word_orig in transformed_words:
                    transformed_words = []
                    for transformed_word in transformation["transform"](transformed_word_orig):
                        if transformed_word in symbol_ids_by_symbol: 
                            matches.append(transformed_word)
                            word_id = ""
                            if transformed_word not in word_ids_by_transformed_word: 
                                # This might not be the best way to insert. TODO: look at the proper way to handle this.
                                words_cur.execute("INSERT INTO words (word) VALUES (%s) ON CONFLICT (word) DO UPDATE SET word = EXCLUDED.word RETURNING id;", (transformed_word, ))
                                word_id = words_cur.fetchone()[0]
                                word_ids_by_transformed_word[transformed_word] = word_id
                            else:
                                word_id = word_ids_by_transformed_word[transformed_word]
                            if word_id:
                                ocr_processors__figures__words_cur.execute('''
                                INSERT INTO ocr_processors__figures__words (ocr_processor_id, figure_id, word_id, transforms)
                                VALUES (%s, %s, %s, %s)
                                ON CONFLICT DO NOTHING;
                                ''',
                                (ocr_processor_id, figure_id, word_id, json.dumps(args[0:len(transforms_applied)])))
                        else:
                            transformed_words.append(transformed_word)

            if len(matches) > 0 and ''.join(matches) != word:
                print('\t' + word + ' => ' + ' & '.join(matches))
            else:
                fails.append(word)

        print('FAILS: could not find matches for the following')
        print('\t\n\t'.join(fails))
        conn.commit()
        print('matching done')

    except(psycopg2.DatabaseError, e):
        print('Error %s' % psycopg2.DatabaseError)
        print('Error %s' % e)
        sys.exit(1)
        
    finally:
        if conn:
            conn.close()
