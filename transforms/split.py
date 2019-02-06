import os, sys
# needed to import deadline from parent dir
sys.path.insert(1, os.path.join(sys.path[0], '..'))

import json
import re
from itertools import product
from pathlib import Path, PurePath

from deadline import deadline, TimedOutExc


# symbol_chars.json is obtained by running ../get_all_symbol_chars.py
# NOTE: symbol_chars.json is missing things would be in gene mentions but not symbols,
# such as comma, but that's ok, because those parts should be in the frozen zone(s).
symbol_chars = set(json.loads(open(Path(PurePath(os.path.dirname(__file__), "symbol_chars.json")), "r").read()))
#CURRENT_SCRIPT_PATH = os.path.dirname(sys.argv[0])
#symbol_chars = set(json.loads(open(Path(PurePath(CURRENT_SCRIPT_PATH, "symbol_chars.json")), "r").read()))
#symbol_chars = set(json.loads(open(Path(PurePath("./symbol_chars.json")), "r").read()))

TIMEOUT = 1

WORD_BOUNDARY = 'PFOCRSPACE'

word_boundary_re = re.compile('\\n')
frozen_sub_chunk_re = re.compile('([\w\-\\n])+')

frozen_zone_re_strings = [
        '\d+(?:\s?\D\s?\d+)+',
        '\d(?:\,\s?\d)*\,?\s(?:and|or|&)\s\d',
        '\s(?:and|or|&)\s',
        # TODO: should this be 2 or 3?
        '\d{2,}'
        ]
frozen_zone_re_string_concatenated = '((?:' + ')|(?:'.join(frozen_zone_re_strings) + '))'
frozen_zone_re = re.compile(frozen_zone_re_string_concatenated)


# Based on https://github.com/orsinium/homoglyphs/blob/master/homoglyphs/core.py
def get_variations(chunk='', frozen_prefix='', frozen_suffix=''):
    if chunk == '':
        yield frozen_prefix + chunk + frozen_suffix
    else:
        variations = []
        for sub_chunk in chunk:
            hgs = [sub_chunk]
            if not frozen_sub_chunk_re.match(sub_chunk):
                hgs.append('\n')
                hgs.append('')
            variations.append(hgs)
        if variations:
            for variant in product(*variations):
                yield frozen_prefix + ''.join(variant) + frozen_suffix

        return variations

def get_next_frozen_prefixes(chunk, frozen_prefixes, frozen_suffix=''):
    next_frozen_prefixes = []
    for frozen_prefix in frozen_prefixes:
        for next_frozen_prefix in get_variations(chunk, frozen_prefix, frozen_suffix):
            next_frozen_prefixes.append(next_frozen_prefix)
    return next_frozen_prefixes

def _split(text, split_re):
    chunks_and_frozen_zones = split_re.split(text)

    frozen_prefixes = ['']
    for chunk,frozen_suffix in zip(chunks_and_frozen_zones[0::2], chunks_and_frozen_zones[1::2]):
        frozen_prefixes = get_next_frozen_prefixes(chunk, frozen_prefixes, frozen_suffix)

    final_chunk = chunks_and_frozen_zones[len(chunks_and_frozen_zones) - 1]
    return get_next_frozen_prefixes(final_chunk, frozen_prefixes)

# the symbols column never has spaces, but it does have underscores
# ABL_family

#@deadline(TIMEOUT)
def split(text):
    result = []
    try:
        result = _split(text, frozen_zone_re)
        if not result:
            result = [text]
        else:
            result_unique = set()
            for r in result:
                for w in word_boundary_re.split(r):
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
