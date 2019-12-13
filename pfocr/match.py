#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import hashlib
import json
import psycopg2
import psycopg2.extras
import re
import transforms
import os
import sys
from pathlib import Path

from deadline import deadline
from get_pg_conn import get_pg_conn
#from match_testable import match, match_logged, match_verbose
import match_testable
#from fast_match_testable import match

FILE_DIR = os.path.dirname(__file__)

alphanumeric_re = re.compile('\w')


#@deadline(20)
def attempt_match(args, matcher_id, transformed_word_ids_by_transformed_word, matches, transforms_applied, match_attempts_cur, transformed_words_cur, ocr_processor_id, figure_id, word, symbol_id, transformed_word):
    if transformed_word:
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
    else:
        transformed_word_id = None

    transform_args = []
    for t in args[0:len(transforms_applied)]:
        transform_args.append("-" + t["category"][0] + " " + t["name"])

    if not word == '':
        match_attempts_cur.execute('''
            INSERT INTO match_attempts (ocr_processor_id, matcher_id, figure_id, word, transformed_word_id, symbol_id, transforms_applied)
            VALUES (%s, %s, %s, %s, %s, %s, %s)
            ON CONFLICT DO NOTHING;
            ''',
            (ocr_processor_id, matcher_id, figure_id, word, transformed_word_id, symbol_id, " ".join(transform_args))
        )

def match(db, output_dir, args):
    conn = get_pg_conn(db)
    ocr_processors__figures_cur = conn.cursor(cursor_factory=psycopg2.extras.DictCursor)
    symbols_cur = conn.cursor(cursor_factory=psycopg2.extras.DictCursor)
    matchers_cur = conn.cursor(cursor_factory=psycopg2.extras.DictCursor)
    transformed_words_cur = conn.cursor(cursor_factory=psycopg2.extras.DictCursor)
    match_attempts_cur = conn.cursor(cursor_factory=psycopg2.extras.DictCursor)

    transforms_for_testable = args.copy()
    transforms_for_testable.insert(0, {
        "name": "split",
        "category": "mutate",
        })

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
        with open(Path(FILE_DIR, "transforms", name + ".py"), "r") as f:
            code = f.read().encode()
            transform_json["code_hash"] = hashlib.sha224(code).hexdigest()
        transforms_json.append(transform_json)

    transforms_json_str = json.dumps(transforms_json)
    matchers_cur.execute(
        '''
        SELECT id FROM matchers WHERE transforms=%s;
        ''',
        (transforms_json_str, )
    )

    matcher_ids = matchers_cur.fetchone()
    if matcher_ids != None:
        matcher_id = matcher_ids[0]
    else:
        matchers_cur.execute(
            '''
            INSERT INTO matchers (transforms)
            VALUES (%s)
            ON CONFLICT (transforms) DO UPDATE SET transforms = EXCLUDED.transforms
            RETURNING id;
            ''',
            (transforms_json_str, )
        )
        matcher_id = matchers_cur.fetchone()[0]

    if matcher_id == None:
        raise Exception("matcher_id not found!");

    normalizations = []
    for t in transforms_to_apply:
        t_category = t["category"]
        if t_category == "normalize":
            normalizations.append(t)

    try:
        #SELECT ocr_processor_id, figure_id, jsonb_extract_path(result, 'fullTextAnnotation', 'text') AS full_text
        ocr_processors__figures_query = '''
        SELECT ocr_processor_id, figure_id, jsonb_extract_path(result, 'textAnnotations', '0', 'description') AS full_text
        FROM ocr_processors__figures ORDER BY ocr_processor_id, figure_id;
        '''
        ocr_processors__figures_cur.execute(ocr_processors__figures_query)

        symbols_query = '''
        SELECT id, symbol
        FROM symbols;
        '''
        symbols_cur.execute(symbols_query)

        # original symbol incl/
        symbol_ids_by_symbol = {}
        symbols_and_ids = list()
        for s in symbols_cur:
            symbols_and_ids.append(s)
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

        for row in ocr_processors__figures_cur:
            ocr_processor_id = row["ocr_processor_id"]
            #print("ocr_processor_id: %s" % ocr_processor_id)
            #print("ocr_processor_id:")
            #print(ocr_processor_id)
            figure_id = row["figure_id"]
            full_text = row["full_text"]
            if full_text:
                fig_matches = set()
                for line in full_text.split("\n"):
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
                            try:
                                for transformed_word_prev in [x for x in transformed_words if alphanumeric_re.match(x)]:
                                    transformed_words = []
                                    for transformed_word in transform_to_apply["transform"](transformed_word_prev):
                                        # perform match for original and uppercased words (see elif)

                                        try:
                                            if transformed_word in symbol_ids_by_symbol: 
                                                attempt_match(
                                                    args, matcher_id, transformed_word_ids_by_transformed_word, matches,
                                                    transforms_applied, match_attempts_cur, transformed_words_cur, ocr_processor_id,
                                                    figure_id, word, symbol_ids_by_symbol[transformed_word], transformed_word)
                                            elif transformed_word.upper() in symbol_ids_by_symbol:
                                                attempt_match(
                                                    args, matcher_id, transformed_word_ids_by_transformed_word, matches,
                                                    transforms_applied, match_attempts_cur, transformed_words_cur, ocr_processor_id,
                                                    figure_id, word, symbol_ids_by_symbol[transformed_word.upper()], transformed_word.upper())
                                            else:
                                                transformed_words.append(transformed_word)

                                    #    except TimedOutExc as e:
                                    #        print "took too long"

                                        except(Exception) as e:
                                            print('transformed_word:', transformed_word)
                                            print('transforms_applied:', transforms_applied)
                                            raise

                            except(Exception) as e:
                                print('Unexpected Error:', e)
                                print('figure_id:', figure_id)
                                print('word:', word)
                                print('transformed_words:')
                                print(transformed_words)
                                raise

                        if len(matches) == 0:
                            attempt_match(args, matcher_id, transformed_word_ids_by_transformed_word, matches, transforms_applied, match_attempts_cur, transformed_words_cur, ocr_processor_id, figure_id, word, None, None)
                    if len(matches) > 0:
                        successes.append(line + ' => ' + ' & '.join(matches))
                    else:
                        fails.append(line)
                    fig_matches.update(matches)

                testable_words = set()
                for line in full_text.split("\n"):
                    testable_words.add(line.replace(" ", ""))
                    for w in line.split(" "):
                        testable_words.add(w)
                #match_testable_matches = match_testable.match(symbols_and_ids, transforms_for_testable, [full_text])
                match_testable_matches = match_testable.match(symbols_and_ids, args, testable_words)
                figure_matches_upper = set()
                for f in fig_matches:
                    figure_matches_upper.add(f.upper())
                if figure_matches_upper != match_testable_matches:
                    print('')
                    print('=========================================')
                    print('figure_id:' + str(figure_id))
                    print('=========================================')

                    print('full_text:')
                    print(str(full_text))
                    fig_matches_expected = list()
                    for f in (fig_matches|match_testable_matches):
                        if f in symbol_ids_by_symbol:
                            fig_matches_expected.append({
                                "symbol": f,
                                "id": symbol_ids_by_symbol[f],
                                })
                        else:
                            print("symbol " + f + " missing from symbol_ids_by_symbol")
                    # print('fig_matches_expected:')
                    # print(fig_matches_expected)

                    print('common:')
                    print(str(figure_matches_upper & match_testable_matches))

                    if not figure_matches_upper <= match_testable_matches:
                        print('in old only:')
                        print(str(figure_matches_upper - match_testable_matches))

                    if not match_testable_matches <= figure_matches_upper:
                        print('in new only:')
                        print(str(match_testable_matches - figure_matches_upper))

#                     print('figure_matches_upper as sorted list:')
#                     print(sorted(list(figure_matches_upper)))
#                     print('match_testable_matches as sorted list:')
#                     print(sorted(list(match_testable_matches)))
#                     print('figure_matches_upper != match_testable_matches')

                    # TODO: use logging https://docs.python.org/3.8/library/logging.html#module-logging
                    # raise Warning('figure_matches_upper != match_testable_matches')
                    # raise Exception('figure_matches_upper != match_testable_matches')

        conn.commit()

        with open(Path(output_dir, "/successes.txt"), "a+") as successesfile:
            successesfile.write('\n'.join(successes))

        with open(Path(output_dir, "fails.txt"), "a+") as failsfile:
            failsfile.write('\n'.join(fails))

        print('match: SUCCESS')

    except(psycopg2.DatabaseError) as e:
        print('Database Error %s' % psycopg2.DatabaseError)
        print('Database Error (same one): %s' % e)
        print('Database Error (same one):', e)
        raise

    except(Exception) as e:
        print('Unexpected Error:', e)
        raise

    finally:
        if conn:
            conn.close()
