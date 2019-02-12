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

from deadline import deadline, TimedOutExc
from regexes import always_split_re, frozen_zone_re


TIMEOUT = 10

MAX_PREFIX_LENGTH = 40

WORD_BOUNDARY = 'PFOCRSPACE'

word_boundary_re = re.compile(WORD_BOUNDARY)
frozen_sub_chunk_re = re.compile('(\w)+')

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

tail_re = re.compile('(?:' + WORD_BOUNDARY + ')(.{2,40})(?:' + WORD_BOUNDARY + ')$')


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
    next_frozen_prefixes = set()
    for frozen_prefix_raw in frozen_prefixes:
        frozen_prefix = ''
        # TODO: verify the following
        # It is supposed to handle very long inputs
        if len(frozen_prefix_raw) > MAX_PREFIX_LENGTH:
            shortened = tail_re.search(frozen_prefix)
            if shortened:
                frozen_prefix = shortened.group(1)
        else:
            frozen_prefix = frozen_prefix_raw
        for next_frozen_prefix in get_variations(chunk, frozen_prefix, frozen_suffix):
            next_frozen_prefixes.add(next_frozen_prefix)
    return next_frozen_prefixes

@deadline(TIMEOUT)
def split(text):
    result = []
    try:
        candidates = set()
        for line in always_split_re.split(text):
            chunks_and_frozen_zones = frozen_zone_re.split(line)
            frozen_prefixes = {''}
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