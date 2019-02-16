#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import re
import transforms
import sys
from Levenshtein import distance

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
    return to_underscore_re.sub('_', word.strip().upper())

# Find match(es) from the OCR full text from a single figure
def attempt_match(symbol_ids_by_symbol, transform_names_categories_functions, successes, fails, current_match_log_entries, text, transform_index=0):
    if not has_alphanumeric_re.match(text):
        fails.append(current_match_log_entries)
        return None

    text_normalized = normalize_always(text)
    if text_normalized in symbol_ids_by_symbol: 
        current_match_log_entries_copy = current_match_log_entries.copy()
        current_match_log_entries_copy.append(text_normalized)
        successes.append(current_match_log_entries_copy)
        return None

    if transform_index >= len(transform_names_categories_functions):
        fails.append(current_match_log_entries)
        return None

    transform_name_category_function = transform_names_categories_functions[transform_index]
    transform_name = transform_name_category_function["name"]
    transform_function = transform_name_category_function["function"]
    transform_index += 1
    for transformed_text in transform_function(text):
        current_match_log_entries_copy = current_match_log_entries.copy()
        current_match_log_entries_copy.append(transformed_text)
        attempt_match(symbol_ids_by_symbol, transform_names_categories_functions, successes, fails, current_match_log_entries_copy, transformed_text, transform_index)

def sort_match_log_subgroups(match_log_subgroup):
    return ''.join(match_log_subgroup)

def create_symbol_ids_by_symbol(symbols_and_ids, transform_names_categories_functions):
    normalizations = []
    for t in transform_names_categories_functions:
        t_category = t["category"]
        if t_category == "normalize":
            normalizations.append(t)

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

    return symbol_ids_by_symbol

# texts is a list of full text strings from the OCR, one per figure.
def match_logged(symbols_and_ids, transform_names_and_categories, texts):
    # transform_names_categories_functions includes both mutations and normalizations
    transform_names_categories_functions = []
    for transform_name_and_category in transform_names_and_categories:
        category = transform_name_and_category["category"]
        name = transform_name_and_category["name"]
        transform_function = getattr(getattr(transforms, name), name)
        transform_names_categories_functions.append({"function": transform_function, "name": name, "category": category})

    try:
        symbol_ids_by_symbol = create_symbol_ids_by_symbol(symbols_and_ids, transform_names_categories_functions)

        successes_groups = list()
        fails_groups = list()
        for text in texts:
            successes_subgroups = list()
            fails_subgroups = list()
            attempt_match(symbol_ids_by_symbol, transform_names_categories_functions, successes_subgroups, fails_subgroups, [text], text)
            # NOTE: w/out applying sorted, we get non-deterministic sort order
            successes_groups.append(sorted(successes_subgroups, key=sort_match_log_subgroups))
            fails_groups.append(sorted(fails_subgroups, key=sort_match_log_subgroups))
        return [successes_groups, fails_groups]

    except(Exception) as e:
        print('Unexpected Error in match_verbose:', e)
        raise

# texts is a list of full text strings from the OCR, one per figure.
def match_verbose(symbols_and_ids, transform_names_and_categories, texts):
    # transform_names_categories_functions includes both mutations and normalizations
    transform_names_categories_functions = []
    for transform_name_and_category in transform_names_and_categories:
        category = transform_name_and_category["category"]
        name = transform_name_and_category["name"]
        transform_function = getattr(getattr(transforms, name), name)
        transform_names_categories_functions.append({"function": transform_function, "name": name, "category": category})

    try:
        symbol_ids_by_symbol = create_symbol_ids_by_symbol(symbols_and_ids, transform_names_categories_functions)

        result = list()
        # we add noop to transform names to represent [text], which we used as the initial input,
        # where text was not yet transformed at all
        transform_names = ['noop'] + [t["name"] for t in transform_names_categories_functions]
        for text in texts:
            successes_subgroups = list()
            fails_subgroups = list()
            attempt_match(symbol_ids_by_symbol, transform_names_categories_functions, successes_subgroups, fails_subgroups, [text], text)
            # NOTE: w/out applying sorted, we get non-deterministic sort order
            successes = list()
            fails = list()
            successes_by_symbol_id = dict()
            group_level_claimed = set()
            for successes_subgroup in sorted(successes_subgroups, key=sort_match_log_subgroups):
                success = list()
                transformed_text_prev = ''
                # we don't include the final entry in the zip, because that's from the 'always' transform
                for transform_name,transformed_text in zip(transform_names, successes_subgroup[:-1]):
                    length = len(transformed_text)
                    length_prev = len(transformed_text_prev)
                    subgroup_level_claimed = set()
                    indices = list()
                    best_distance = float('inf')
                    best_claim = set()
                    if length_prev >= length:
                        success_element_prev = success[-1]
                        for index_prev in success_element_prev["indices"]:
                            for index in range(0, length_prev - length + 1):
                                new_candidate = transformed_text_prev[index:index + length]
                                current_distance = distance(new_candidate, transformed_text)
                                current_index = index_prev + index
                                candidate_claim = set(range(current_index, current_index + length))
                                if not candidate_claim.issubset(group_level_claimed):
                                    if not candidate_claim.intersection(subgroup_level_claimed):
                                        if current_distance == 0:
                                            indices.append(current_index)
                                            subgroup_level_claimed.update(candidate_claim)
                                    elif not candidate_claim.issubset(subgroup_level_claimed):
                                        if current_distance / length < 0.2:
                                            indices.append(current_index)
                                            subgroup_level_claimed.update(candidate_claim)

                                    if current_distance <= best_distance:
                                        best_claim = candidate_claim
                                        best_distance = current_distance
                    transformed_text_prev = transformed_text
                    success.append({
                        "transform": transform_name,
                        "indices": indices if len(indices) > 0 else [0],
                        "text": transformed_text})
                group_level_claimed.update(best_claim)

                # need to add final entry, including the symbol_id for the match
                text_normalized = successes_subgroup[-1]
                symbol_id = symbol_ids_by_symbol[text_normalized]
                success.append({
                    "transform": "always",
                    "indices": success[-1]["indices"],
                    "text": text_normalized,
                    "symbol_id": symbol_id,
                    })

                successes.append(success)

            for fails_subgroup in sorted(fails_subgroups, key=sort_match_log_subgroups):
                fail = list()
                # we don't include the final entry in the zip, because that's from the 'always' transform
                for transform_name,transformed_text in zip(transform_names, fails_subgroup[:-1]):
                    fail.append({
                        "transform": transform_name,
                        "text": transformed_text})
                # need to add final entry (no symbol_id because no match)
                text_normalized = fails_subgroup[-1]
                fail.append({
                    "transform": "always",
                    "text": text_normalized,
                    })

                fails.append(fail)

            result.append({
                "text": text,
                "successes": successes,
                "fails": fails})

#        for r in result:
#            for success in r["successes"]:
#                for s in success:
#                    s.pop("indices", None)
        return result

    except(Exception) as e:
        print('Unexpected Error in match_verbose:', e)
        raise

def match(symbols_and_ids, transform_names_and_categories, texts):
    # match_log_groups: one per input text ("line")
    # match_log_subgroups: one per "word"
    # match_log_entries: one per transformation

    successes_groups = match_logged(symbols_and_ids, transform_names_and_categories, texts)[0]
    matches = set()
    for successes_subgroups in successes_groups:
        for entries in successes_subgroups:
            matches.add(entries[-1])
    return matches
