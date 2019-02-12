import os, sys
# needed to import deadline from parent dir
sys.path.insert(1, os.path.join(sys.path[0], '..'))

import re
from itertools import product
from pathlib import Path, PurePath

from confusable_homoglyphs import confusables
from deadline import deadline, TimedOutExc


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

# We're using 128 instead of 256 because we want US-ASCII, not extended.
# TODO: what about greek characters like alpha?
# the range for lowercase alpha to omega is 945-969
ASCII_LIMIT = 128

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

def get_ascii_homoglyphs_for_char(char):
    hgs = get_homoglyphs_for_char(char)
    # see https://github.com/orsinium/homoglyphs/blob/master/homoglyphs/core.py

    # We need to use max() below, because we can get multiple character homoglyphs
    # like ['f', 'i'] for an input like the fi ligature.
    result = [hg for hg in hgs if max(map(ord, hg)) < ASCII_LIMIT]
    return result
