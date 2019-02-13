#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import json
import psycopg2
import psycopg2.extras
import re
import transforms
import sys

from deadline import deadline
from get_pg_conn import get_pg_conn

# see https://docs.python.org/3/library/re.html?highlight=re#writing-a-tokenizer

# we need re.DOTALL to handle cases like '\nABC1'
has_alphanumeric_re = re.compile('.*\w.*', re.DOTALL)
to_underscore_re = re.compile('[ \t]')

# NOTE: all single letter symbols have already been removed from the lexicon
# NOTE: all double letter symbols have already been removed from prev_symbol, alias_symbol; 
#       some remain from current HGNC symbols and bioentities sources, e.g., GK, GA and HR.
# NOTE: entries should be upper and alphanumeric-only
stop_words = {"2", "CO2", "HR", "GA", "CA2", "TYPE",
        "DAMAGE", "GK", "S21", "TAT", "L10","CYCLIN",
	"CAMP","FOR","DAG","PIP","FATE","ANG",
	"NOT","CAN","MIR","CEL","ECM","HITS","AID","HDS",
	"REG","ROS", "D1", "CALL", "BEND3"}

# We run this normalization regardless of the -n and -m items specified
def normalize_always(word):
    return to_underscore_re.sub('_', word.upper())

# Find match(es) from the OCR full text from a single figure
def match_one(transform_names_categories_functions, symbol_ids_by_symbol, text):
    try:
        matches = set()
        transforms_applied = []
        transformed_words = [text]
        for transform_name_category_function in transform_names_categories_functions:
            transform_name = transform_name_category_function["name"]
            transform_category = transform_name_category_function["category"]
            transforms_applied.append(transform_name)
            for transformed_word_prev in [x for x in transformed_words if has_alphanumeric_re.match(x)]:
                transformed_words = []
                # the symbols column never has spaces, but it does have underscores
                # ABL_family
                for transformed_word in transform_name_category_function["function"](transformed_word_prev):
                    normalized_transformed_word = normalize_always(transformed_word)
                    if normalized_transformed_word in symbol_ids_by_symbol: 
                        matches.add(normalized_transformed_word)
                    else:
                        transformed_words.append(transformed_word)

        return matches

    except(Exception) as e:
        print('Unexpected Error in match_one:', e)
        raise

# texts is a list of full text strings from the OCR, one per figure.
def match_multiple(transform_names_and_categories, texts, symbols_and_ids):
    # transform_names_categories_functions includes both mutations and normalizations
    transform_names_categories_functions = []
    for transform_name_and_category in transform_names_and_categories:
        category = transform_name_and_category["category"]
        name = transform_name_and_category["name"]
        transform_function = getattr(getattr(transforms, name), name)
        transform_names_categories_functions.append({"function": transform_function, "name": name, "category": category})

    normalizations = []
    for t in transform_names_categories_functions:
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
                        n_always = normalize_always(n)
                        if (n_always not in symbol_ids_by_symbol) and (n_always not in stop_words):
                            symbol_ids_by_symbol[n_always] = symbol_id

        all_matches = set()
        for text in texts:
            for m in match_one(transform_names_categories_functions, symbol_ids_by_symbol, text):
                all_matches.add(m)

        return all_matches

    except(Exception) as e:
        print('Unexpected Error in match_multiple:', e)
        raise

def match(transform_names_and_categories, texts, symbols_and_ids):
    return match_multiple(transform_names_and_categories, texts, symbols_and_ids)
