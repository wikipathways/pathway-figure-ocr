import os, sys
# TODO: fix this package so we can import from ../ and ../utils
# needed to import deadline from parent dir
sys.path.insert(1, os.path.join(os.path.dirname(__file__), '..'))
# needed to import from utils dir.
sys.path.insert(1, os.path.join(os.path.dirname(__file__), '..', 'utils'))

import json
import re
from itertools import product
from pathlib import Path, PurePath

from confusable_homoglyphs import confusables
from deadline import deadline, TimedOutExc
from regexes import frozen_zone_re


# symbol_chars.json is obtained by running ../get_all_symbol_chars.py
# NOTE: symbol_chars.json is missing things would be in gene mentions but not symbols,
# such as comma, but that's ok, because those parts should be in the frozen zone(s).
symbol_chars_raw = json.loads(open(Path(PurePath(os.path.dirname(__file__), "..", "..", "symbol_chars.json")), "r").read())
# TODO: pre-process this.
symbol_chars = set([char.upper() for char in symbol_chars_raw])
#CURRENT_SCRIPT_PATH = os.path.dirname(sys.argv[0])
#symbol_chars = set(json.loads(open(Path(PurePath(CURRENT_SCRIPT_PATH, "symbol_chars.json")), "r").read()))
#symbol_chars = set(json.loads(open(Path(PurePath("./symbol_chars.json")), "r").read()))

# Relevant links:
# https://confusable-homoglyphs.readthedocs.io/en/latest/apidocumentation.html
# https://github.com/orsinium/homoglyphs
# https://en.wikipedia.org/wiki/Typographic_ligature
#   discusses ae letter vs fi ligature
#
# https://github.com/endgameinc/homoglyph
# https://github.com/codebox/homoglyph/blob/master/generator/source_data/confusables.txt
# http://homoglyphs.net/
# https://stackoverflow.com/questions/3194516/replace-special-characters-with-ascii-equivalent

# Semi-relevant links (mostly deburr-related):
# https://github.com/mozilla/unicode-slugify
# https://pypi.org/project/unicode-slugify-latin/
# https://pypi.org/project/Unidecode/
# https://github.com/kmike/text-unidecode
# http://effbot.org/zone/unicode-convert.htm
#   this isn't focused on homoglyphs but does have a list of latin characters without
#   a unicode decompositi

TIMEOUT = 2

# note: we probably want to make this larger if we ever do non-genes
# to handle items like Phosphatidylethanolamine
WORD_LENGTH_LIMIT = 25
#select symbol from symbols WHERE length(symbol) = (SELECT max(length(symbol)) FROM symbols);
#          symbol
#---------------------------
# Propionyl_CoA_carboxylase
# Interferon_gamma_receptor
# Annexin_II_heterotetramer

#CHUNK_COUNT_LIMIT = 3
#CHUNK_LENGTH_LIMIT = 25
#CHUNK_TOTAL_LENGTH_LIMIT = 25

# We're using 128 instead of 256 because we want US-ASCII, not extended.
# TODO: what about greek characters like alpha?
# the range for lowercase alpha to omega is 945-969
ASCII_LIMIT = 128

FROZEN_CHARS = {' ', '\n'}
char_to_hg_mappings = {}
#input_to_variation_mappings = {}


def get_homoglyphs_for_char(char, prev_char=None):
    # NOTE: we can safely just take the first result, because we only accept a single character
    confusables_result = confusables.is_confusable(char, preferred_aliases=[], greedy=True)
    hgs = []
    if not confusables_result:
        hgs = [char]
    else:
        hgs = list(map(lambda x: x['c'], confusables_result[0]['homoglyphs']))
        if not hgs:
            raise Exception("Error with confusable_homoglyphs: Result not False but no homoglyphs for '%s'." % char)
        elif len(hgs) == 1 and len(hgs[0]) == 1:
            # The first part of the check above is a kludge for these issues:
            # https://github.com/vhf/confusable_homoglyphs/issues/10
            # https://github.com/vhf/confusable_homoglyphs/issues/13
            # The first homoglyph result is just a pointer to a second homoglyph (single character).
            # Getting homoglyphs for that second homoglyph gives the full set of homoglyphs.
            #
            # The second part of the check is to handle cases like the "ae" letter.
            # For the "ae" letter, len(hgs) will be 1, but len(hgs[0])
            # will be 2 for the two separate characters 'a' and 'e'.
            # We only want 'ae', not all homoglyphs for 'a' and for 'e'.

            next_char = hgs[0]
            if prev_char == None:
                hgs_full = get_homoglyphs_for_char(next_char, char)
                # we want to keep the value from the OCR as the first in the list
                hgs = [hg for hg in hgs_full if hg != char]
                hgs.insert(0, char)
            else:
                # we want to keep the value from the OCR as the first in the list
                # in this case, char is NOT the value from the OCR
                hgs.append(char)
        else:
            # we want to keep the value from the OCR as the first in the list
            hgs.insert(0, char)

    return hgs

def is_in_symbol_chars(chars):
    is_in = True
    for char in chars:
        is_in = is_in and (char.upper() in symbol_chars)
    return is_in

def get_symbol_homoglyphs_for_char(char):
    # NOTE: We don't want to remove spaces.
    # TODO: Should we do this with the frozen_zone_re_strings instead?
    if char in FROZEN_CHARS:
        return [char]
    elif char in char_to_hg_mappings:
        return char_to_hg_mappings[char]
    else:
        hgs = get_homoglyphs_for_char(char)
        # see https://github.com/orsinium/homoglyphs/blob/master/homoglyphs/core.py

        # We need to use max() below, because we can get multiple character homoglyphs
        # like ['f', 'i'] for an input like the fi ligature.
        result = [hg for hg in hgs if is_in_symbol_chars(hg)]
        char_to_hg_mappings[char] = result
        return result

# Based on https://github.com/orsinium/homoglyphs/blob/master/homoglyphs/core.py
def _homoglyphs2symbol_chars_chunk(chunk='', frozen_prefix='', frozen_suffix=''):
    if chunk == '':
        yield frozen_prefix + chunk + frozen_suffix
    else:
        variations = []
        for char in chunk:
            hgs = get_symbol_homoglyphs_for_char(char)
            if hgs:
                variations.append(hgs)
        if variations:
            for variant in product(*variations):
                yield frozen_prefix + ''.join(variant) + frozen_suffix

        return variations

def _homoglyphs2symbol_chars(text):
    chunks_and_frozen_zones = frozen_zone_re.split(text)
    char_count = len(text)
    # TODO: how should we handle inputs that are too long and hang the process?
#    if char_count > WORD_LENGTH_LIMIT:
#        sys.stderr.write("\r\nhomoglyphs2symbol_chars warning: input text below is too long. WORD_LENGTH_LIMIT is %s.\r\n" % WORD_LENGTH_LIMIT)
#        sys.stderr.write(text)
#        #sys.stderr.write('\r\nreturning input text unchanged.\r\n')
#        return []

#    chunk_count = (len(chunks_and_frozen_zones) - 1)/2 + 1
#    if chunk_count > CHUNK_COUNT_LIMIT or len(text) > WORD_LENGTH_LIMIT:
#        return [text]

    next_frozen_prefixes = ['']
    for chunk,frozen_suffix in zip(chunks_and_frozen_zones[0::2], chunks_and_frozen_zones[1::2]):
        frozen_prefixes = next_frozen_prefixes
        next_frozen_prefixes = []
        for frozen_prefix in frozen_prefixes:
            # TODO: for a case like 'RIG123 and DEF', we are running _homoglyphs2symbol_chars_chunk
            # multiple times for DEF, once for every homoglyph variation of RIG123
            # We might be able to improve this if we created an in-memory lookup table
            # of homoglyph variations for chunks.
            for next_frozen_prefix in _homoglyphs2symbol_chars_chunk(chunk, frozen_prefix, frozen_suffix):
                next_frozen_prefixes.append(next_frozen_prefix)

    final_chunk = chunks_and_frozen_zones[len(chunks_and_frozen_zones) - 1]
    frozen_prefixes = next_frozen_prefixes
    next_frozen_prefixes = []
    for frozen_prefix in frozen_prefixes:
        for next_frozen_prefix in _homoglyphs2symbol_chars_chunk(final_chunk, frozen_prefix):
            next_frozen_prefixes.append(next_frozen_prefix)

    return next_frozen_prefixes


@deadline(TIMEOUT)
# Note: case insensitive
def homoglyphs2symbol_chars(text):
    result = []
    try:
        result = _homoglyphs2symbol_chars(text)

#        # TODO: if the original text is in the result, we want it to be first.
#        # But if it's not, do we want to add it to the list?
#        if not result:
#            result = [text]
#        elif result[0] != text:
#            ...

        if not result:
            result = []
        #elif result[0] != text:
        # TODO: we could also sort by something like Levenshtein distance.
        elif text in result and result[0] != text:
            result = [r for r in result if r != text]
            result.insert(0, text)
        # else is not needed, because it'd just be result = result

#        text_is_ascii = max(map(ord, text)) < ASCII_LIMIT
#        if not result:
#            if text_is_ascii:
#                result = [text]
#            else:
#                result = []
#        else:
#            if text_is_ascii and result[0] != text:
#                # we want to keep the value from the OCR as the first in the list
#                result = [r for r in result if r != text]
#                result.insert(0, text)
#            # else is not needed, because it'd just be result = result
    except TimedOutExc as e:
        sys.stderr.write('\r\nhomoglyphs2symbol_chars warning: timed out for this input text:\r\n')
        sys.stderr.write(text)
        sys.stderr.write('\r\nreturning input text unchanged.\r\n')
        raise
        #result = [text]
        #pass
    except:
        result = [text]
        sys.stderr.write('\r\nhomoglyphs2symbol_chars error: could not handle this input text:\r\n')
        sys.stderr.write(text)
        raise
        #pass
    return result
