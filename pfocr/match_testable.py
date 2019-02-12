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
#whitespace_re = re.compile('\s', re.ASCII)
whitespace_re = re.compile('[ \t]')
#whitespace_re = re.compile('\ ')

# NOTE: all single letter symbols have already been removed from the lexicon
# NOTE: all double letter symbols have already been removed from prev_symbol, alias_symbol; 
#       some remain from current HGNC symbols and bioentities sources, e.g., GK, GA and HR.
# NOTE: entries should be upper and alphanumeric-only
stop_words = {"2", "CO2", "HR", "GA", "CA2", "TYPE",
        "DAMAGE", "GK", "S21", "TAT", "L10","CYCLIN",
	"CAMP","FOR","DAG","PIP","FATE","ANG",
	"NOT","CAN","MIR","CEL","ECM","HITS","AID","HDS",
	"REG","ROS", "D1", "CALL", "BEND3"}

def normalize_default(word):
    return whitespace_re.sub('_', word.upper())

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
                        n_default = normalize_default(n)
                        if (n_default not in symbol_ids_by_symbol) and (n_default not in stop_words):
                            symbol_ids_by_symbol[n_default] = symbol_id

        all_matches = set()
        for full_text in ocr_texts:
            matches = set()
            transforms_applied = []
            transformed_words = [full_text]
            for transform_to_apply in transforms_to_apply:
                transforms_applied.append(transform_to_apply["name"])
                # TODO: re-enable this?
                #for transformed_word_prev in [x for x in transformed_words if alphanumeric_re.match(x)]:
                for transformed_word_prev in transformed_words:
                    transformed_words = []
                    # the symbols column never has spaces, but it does have underscores
                    # ABL_family
                    for transformed_word in transform_to_apply["function"](transformed_word_prev):
                        normalized_transformed_word = normalize_default(transformed_word)
                        if normalized_transformed_word in symbol_ids_by_symbol: 
                            matches.add(normalized_transformed_word)
                            all_matches.add(normalized_transformed_word)
                        else:
                            transformed_words.append(transformed_word)

        return all_matches

    except(Exception) as e:
        print('Unexpected Error:', e)
        raise
