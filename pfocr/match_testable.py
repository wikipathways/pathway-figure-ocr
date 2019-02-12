#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import hashlib
import json
import psycopg2
import psycopg2.extras
import re
import transforms
import sys
from deadline import deadline
from get_pg_conn import get_pg_conn


# see https://docs.python.org/3/library/re.html?highlight=re#writing-a-tokenizer


alphanumeric_re = re.compile('\w')


def match_testable(transform_recipes, ocr_texts, symbols_and_ids):
    # transforms_to_apply includes both mutations and normalizations
    transforms_to_apply = []
    for transform_recipe in transform_recipes:
        category = transform_recipe["category"]
        name = transform_recipe["name"]
        transform_function = getattr(getattr(transforms, name), name)
        transforms_to_apply.append({"function": transform_function, "name": name, "category": category})

    normalizations = []
    for t in transforms_to_apply:
        t_category = t["category"]
        if t_category == "normalize":
            normalizations.append(t)

    try:
        # original symbol incl/
        symbol_ids_by_symbol = {}
        for s in symbols_and_ids:
            symbol_id = s["id"]
            symbol = s["symbol"]
            normalized_results = [symbol]
            for normalization in normalizations:
                for normalized in normalized_results:
                    normalized_results = []
                    for n in normalization["function"](normalized):
                        normalized_results.append(n)
                        if n not in symbol_ids_by_symbol: 
                            symbol_ids_by_symbol[n] = symbol_id
                        # Also collect unique uppercased symbols for matching
                        if n.upper() not in symbol_ids_by_symbol:
                            symbol_ids_by_symbol[n.upper] = symbol_id

        all_matches = set()
        for full_text in ocr_texts:
            matches = set()
            transforms_applied = []
            transformed_words = [full_text]
            for transform_to_apply in transforms_to_apply:
                transforms_applied.append(transform_to_apply["name"])
                #for transformed_word_prev in [x for x in transformed_words if alphanumeric_re.match(x)]:
                for transformed_word_prev in transformed_words:
                    transformed_words = []
                    for transformed_word in transform_to_apply["function"](transformed_word_prev):
                        # perform match for original and uppercased words (see elif)

                        if transformed_word in symbol_ids_by_symbol: 
                            matches.add(transformed_word)
                            all_matches.add(transformed_word)
#                                elif transformed_word.upper() in symbol_ids_by_symbol:
#                                    attempt_match(
#                                        args, matcher_id, transformed_word_ids_by_transformed_word, matches,
#                                        transforms_applied, match_attempts_cur, transformed_words_cur, ocr_processor_id,
#                                        figure_id, word, symbol_ids_by_symbol[transformed_word.upper()], transformed_word.upper())
                        else:
                            transformed_words.append(transformed_word)

#                    if len(matches) == 0:
#                        attempt_match(args, matcher_id, transformed_word_ids_by_transformed_word, matches, transforms_applied, match_attempts_cur, transformed_words_cur, ocr_processor_id, figure_id, word, None, None)

        return all_matches

    except(Exception) as e:
        print('Unexpected Error:', e)
        raise
