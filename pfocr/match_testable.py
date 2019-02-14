#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import json
import re
import transforms
import sys

from deadline import deadline

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
def attempt_match(symbol_ids_by_symbol, transform_names_categories_functions, match_log_subgroups, current_match_log_entries, text, transform_index=0):
    if not has_alphanumeric_re.match(text):
        match_log_subgroups.append(current_match_log_entries)
        return None

    normalized_transformed_word = normalize_always(text)
    if normalized_transformed_word in symbol_ids_by_symbol: 
        last_log_element = current_match_log_entries[-1]
        last_log_element["symbol_id"] = symbol_ids_by_symbol[normalized_transformed_word]
        match_log_subgroups.append(current_match_log_entries)
        return None

    if transform_index >= len(transform_names_categories_functions):
        match_log_subgroups.append(current_match_log_entries)
        return None

    transform_name_category_function = transform_names_categories_functions[transform_index]
    transform_name = transform_name_category_function["name"]
    transform_function = transform_name_category_function["function"]
    transform_index += 1
    for transformed_text in transform_function(text):
        current_match_log_entries_copy = current_match_log_entries.copy()
        current_match_log_entries_copy.append({
            "transform": transform_name,
            "text": transformed_text,
            })
        attempt_match(symbol_ids_by_symbol, transform_names_categories_functions, match_log_subgroups, current_match_log_entries_copy, transformed_text, transform_index)

def sort_match_log_subgroups(match_log_subgroup):
    key = ''
    for match_log_entry in match_log_subgroup:
        key += match_log_entry["text"]
    return key

# texts is a list of full text strings from the OCR, one per figure.
def match_verbose(symbols_and_ids, transform_names_and_categories, texts):
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

        match_log_groups = list()
        for text in texts:
            match_log_subgroups = list()
            attempt_match(symbol_ids_by_symbol, transform_names_categories_functions, match_log_subgroups, [{"transform": None, "text": text}], text)
            # NOTE: w/out applying sorted, we get non-deterministic sort order
            match_log_groups.append(sorted(match_log_subgroups, key=sort_match_log_subgroups))
        return match_log_groups

#        with open("./all_successes.json", "w") as f:
#            f.write(json.dumps(all_successes, indent=2))
#        with open("./all_fails.json", "w") as f:
#            f.write(json.dumps(all_fails, indent=2))

    except(Exception) as e:
        print('Unexpected Error in match_multiple:', e)
        raise

def match(symbols_and_ids, transform_names_and_categories, texts):
    # match_log_groups: one per input text ("line")
    # match_log_subgroups: one per "word"
    # match_log_entries: one per transformation

    match_log_groups = match_verbose(symbols_and_ids, transform_names_and_categories, texts)
    matches = set()
    for match_log_subgroups in match_log_groups:
        for match_log_entries in match_log_subgroups:
            final_log_entry = match_log_entries[-1]
            if "symbol_id" in final_log_entry:
                matches.add(final_log_entry["text"])
    return matches
