#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import hashlib
import json
import psycopg2
import psycopg2.extras
import re
import transforms
import sys
from get_conn import get_conn

def attempt_match(args, transformed_word_ids_by_transformed_word, matches, transforms_applied, match_attempts_cur, transformed_words_cur, ocr_processor_id, figure_id, word, transformed_word):
    transformed_word_id = ""
    if transformed_word:
        if transformed_word[0:6] != 'dummy_':
            matches.add(transformed_word)
        if transformed_word not in transformed_word_ids_by_transformed_word: 
	    # This might not be the best way to insert. TODO: look at the proper way to handle this.
            transformed_words_cur.execute(
                '''
                INSERT INTO transformed_words (transformed_word)
                VALUES (%s)
                ON CONFLICT (transformed_word) DO UPDATE SET transformed_word = EXCLUDED.transformed_word
                RETURNING id;
                ''',
                (transformed_word, )
            )
            transformed_word_id = transformed_words_cur.fetchone()[0]
            transformed_word_ids_by_transformed_word[transformed_word] = transformed_word_id
        else:
            transformed_word_id = transformed_word_ids_by_transformed_word[transformed_word]

    #if transformed_word_id:
    transform_args = []
    for t in args[0:len(transforms_applied)]:
        transform_args.append("-" + t["category"][0] + " " + t["name"])

    if not word == '':
        match_attempts_cur.execute('''
            INSERT INTO match_attempts (ocr_processor_id, figure_id, word, transformed_word_id, transforms_applied)
            VALUES (%s, %s, %s, %s, %s)
            ON CONFLICT DO NOTHING;
            ''',
            (ocr_processor_id, figure_id, word, transformed_word_id, " ".join(transform_args))
        )

def match(args):
    conn = get_conn()
    ocr_processors__figures_cur = conn.cursor(cursor_factory=psycopg2.extras.DictCursor)
    symbols_cur = conn.cursor(cursor_factory=psycopg2.extras.DictCursor)
    matchers_cur = conn.cursor(cursor_factory=psycopg2.extras.DictCursor)
    transformed_words_cur = conn.cursor(cursor_factory=psycopg2.extras.DictCursor)
    match_attempts_cur = conn.cursor(cursor_factory=psycopg2.extras.DictCursor)

    # transforms_to_apply includes both mutations and normalizations
    transforms_to_apply = []
    for arg in args:
        category = arg["category"]
        name = arg["name"]
        t = getattr(getattr(transforms, name), name)
        transforms_to_apply.append({"transform": t, "name": name, "category": category})

    transforms_json = []
    for t in transforms_to_apply:
        transform_json = {}
        transform_json["category"] = t["category"]
        name = t["name"]
        transform_json["name"] = name
        with open("./transforms/" + name + ".py", "r") as f:
            code = f.read().encode()
            transform_json["code_hash"] = hashlib.sha224(code).hexdigest()
        transforms_json.append(transform_json)

    matchers_cur.execute(
        '''
        INSERT INTO matchers (transforms)
        VALUES (%s)
        ON CONFLICT (transforms) DO UPDATE SET transforms = EXCLUDED.transforms;
        ''',
        (json.dumps(transforms_json), )
    )

    normalizations = []
    for t in transforms_to_apply:
        t_category = t["category"]
        if t_category == "normalize":
            normalizations.append(t)

    try:
        ocr_processors__figures_query = '''
        SELECT ocr_processor_id, figure_id, jsonb_extract_path(result, 'textAnnotations', '0', 'description') AS description
        FROM ocr_processors__figures;
        '''
        ocr_processors__figures_cur.execute(ocr_processors__figures_query)

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

        transformed_word_ids_by_transformed_word = {}
        transformed_words_cur.execute(
            '''
            SELECT id, transformed_word
            FROM transformed_words;
            '''
        )
        for row in transformed_words_cur:
            transformed_word_id = row["id"]
            transformed_word = row["transformed_word"]
            transformed_word_ids_by_transformed_word[transformed_word] = transformed_word_id

        successes = []
        fails = []
        #print('SUCCESSES: found matches for the following')
        for row in ocr_processors__figures_cur:
            ocr_processor_id = row["ocr_processor_id"]
            figure_id = row["figure_id"]
            paragraph = row["description"]
            if paragraph:
                for line in paragraph.split("\n"):
                    words = set()
                    words.add(line.replace(" ", ""))
                    matches = set()
                    for w in line.split(" "):
                        words.add(w)
                    for word in words:
                        transforms_applied = []
                        transformed_words = [word]
                        for transform_to_apply in transforms_to_apply:
                            transforms_applied.append(transform_to_apply["name"])
                            for transformed_word_prev in transformed_words:
                                transformed_words = []
                                for transformed_word in transform_to_apply["transform"](transformed_word_prev):
                                    # perform match for original and uppercased words (see elif)
                                    if transformed_word in symbol_ids_by_symbol: 
                                        attempt_match(args, transformed_word_ids_by_transformed_word, matches, transforms_applied, match_attempts_cur, transformed_words_cur, ocr_processor_id, figure_id, word, transformed_word)
                                    elif transformed_word.upper() in symbol_ids_by_symbol:
                                        attempt_match(args, transformed_word_ids_by_transformed_word, matches, transforms_applied, match_attempts_cur, transformed_words_cur, ocr_processor_id, figure_id, word, transformed_word.upper())
                                    else:
                                        transformed_words.append(transformed_word)
                        if len(matches) == 0:
                            attempt_match(args, transformed_word_ids_by_transformed_word, matches, transforms_applied, match_attempts_cur, transformed_words_cur, ocr_processor_id, figure_id, word, "dummy_" + word)
                    if len(matches) > 0:
                        successes.append(line + ' => ' + ' & '.join(matches))
                    else:
                        fails.append(line)

        conn.commit()

        with open("./successes.txt", "a+") as successesfile:
            successesfile.write('\n'.join(successes))

        with open("./fails.txt", "a+") as failsfile:
            failsfile.write('\n'.join(fails))

        print('match: SUCCESS')

    except(psycopg2.DatabaseError) as e:
        print('Error %s' % psycopg2.DatabaseError)
        print('Error %s' % e)
        sys.exit(1)
        
    finally:
        if conn:
            conn.close()
