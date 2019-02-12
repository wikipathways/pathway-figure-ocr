import os, sys
# needed to import deadline from parent dir
sys.path.insert(1, os.path.join(sys.path[0], '..'))

import json
import re
from itertools import product
from pathlib import Path, PurePath

from deadline import deadline, TimedOutExc


TIMEOUT = 1

MAX_PREFIX_LENGTH = 40

WORD_BOUNDARY = 'PFOCRSPACE'

word_boundary_re = re.compile(WORD_BOUNDARY)
frozen_sub_chunk_re = re.compile('(\w)+')

frozen_zone_re_strings = [
        '\d+(?:\s?\D\s?\d+)+',
        '\d(?:\,\s?\d)*\,?\s(?:and|or|&)\s\d',
        '\s(?:and|or|&)\s',
        # TODO: should this be 2 or 3?
        '\d{2,}',
        '(?:' + WORD_BOUNDARY + ')'
        ]
frozen_zone_re_string_concatenated = '((?:' + ')|(?:'.join(frozen_zone_re_strings) + '))'
frozen_zone_re = re.compile(frozen_zone_re_string_concatenated)


#\f	ASCII Formfeed (FF)
#\n	ASCII Linefeed (LF)
#\r	ASCII Carriage Return (CR)
#\v	ASCII Vertical Tab (VT)
#\u2190-\u2199  Unicode arrows (basic)

# TODO: what about the following characters?
#\t	ASCII Horizontal Tab (TAB)
#\u2190-\u21FF  Unicode arrows
#\u27F0-\u27FF  Unicode Supplemental Arrows-A
#\u2900-\u297F  Unicode Supplemental Arrows-B
#\u2B00-\u2BFF  Unicode Miscellaneous Symbols and Arrows

always_split_pattern = '\n\r\f\v\u2190-\u2199'
always_split_re = re.compile('[' + always_split_pattern + ']')


# Based on https://github.com/orsinium/homoglyphs/blob/master/homoglyphs/core.py
def get_variations(chunk='', frozen_prefix='', frozen_suffix=''):
    if chunk == '':
        yield frozen_prefix + chunk + frozen_suffix
    else:
        variations = []
        for sub_chunk in chunk:
            hgs = [sub_chunk]
            if not frozen_sub_chunk_re.match(sub_chunk):
                hgs.append(WORD_BOUNDARY)
                hgs.append('')
            variations.append(hgs)
        if variations:
            for variant in product(*variations):
                yield frozen_prefix + ''.join(variant) + frozen_suffix

        return variations

def get_next_frozen_prefixes(chunk, frozen_prefixes, frozen_suffix=''):
    next_frozen_prefixes = []
    for frozen_prefix in [f for f in frozen_prefixes if len(f) <= MAX_PREFIX_LENGTH]:
        for next_frozen_prefix in get_variations(chunk, frozen_prefix, frozen_suffix):
            next_frozen_prefixes.append(next_frozen_prefix)
    return next_frozen_prefixes

# the symbols column never has spaces, but it does have underscores
# ABL_family

#@deadline(TIMEOUT)
def split(text):
    result = []
    try:
#        chunks_and_frozen_zones = frozen_zone_re.split(
#                text)
        chunks_and_frozen_zones = frozen_zone_re.split(
                always_split_re.sub(WORD_BOUNDARY, text))

        candidates = set()
        frozen_prefixes = ['']
        for chunk,frozen_suffix in zip(chunks_and_frozen_zones[0::2], chunks_and_frozen_zones[1::2]):
            frozen_prefixes = get_next_frozen_prefixes(chunk, frozen_prefixes, frozen_suffix)
            for frozen_prefix in [f for f in frozen_prefixes if len(f) > MAX_PREFIX_LENGTH]:
                candidates.add(frozen_prefix)

        final_chunk = chunks_and_frozen_zones[len(chunks_and_frozen_zones) - 1]
        for frozen_prefix in get_next_frozen_prefixes(final_chunk, frozen_prefixes):
            candidates.add(frozen_prefix)

        if not candidates:
            result.append(text)
        else:
            result_unique = set()
            for candidate in candidates:
                for w in word_boundary_re.split(candidate):
                    if w != '' and len(w) > 1 and frozen_sub_chunk_re.match(w):
                        result_unique.add(w)
            result = list(result_unique)

    except TimedOutExc as e:
        sys.stderr.write('\r\split warning: timed out for this input text:\r\n')
        sys.stderr.write(text)
        sys.stderr.write('\r\nreturning input text unchanged.\r\n')
        result = [text]
        pass
    except:
        result = [text]
        sys.stderr.write('\r\nsplit error: could not handle this input text:\r\n')
        sys.stderr.write(text)
        raise
        #pass
    return result
