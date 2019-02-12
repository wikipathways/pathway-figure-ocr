import os, sys

import json
import re
from itertools import product
from pathlib import Path, PurePath

# needed to import hg from utils dir
sys.path.insert(1, os.path.join(os.path.dirname(__file__), '..', 'utils'))
from hg import get_ascii_homoglyphs_for_char
# needed to import hg from utils dir
sys.path.insert(1, os.path.dirname(__file__))
from split import always_split_pattern
## TODO: why don't these work (w/out sys.path.insert):
#from ..utils.hg import get_ascii_homoglyphs_for_char
#from split import always_split_pattern


# Limiting to Basic Latin character set
# TODO: what about greek characters?
basic_latin_pattern = '\u0020-\u007F'
frozen_zone_re = re.compile('([' + basic_latin_pattern + always_split_pattern + ']+)')


# Based on https://github.com/orsinium/homoglyphs/blob/master/homoglyphs/core.py
def get_variations(chunk='', frozen_prefix='', frozen_suffix=''):
    if chunk == '':
        yield frozen_prefix + chunk + frozen_suffix
    else:
        variations = []
        for char in chunk:
            hgs = get_ascii_homoglyphs_for_char(char)
            if len(hgs) == 0:
                hgs = ['']
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

def asciify(text):
    result = []
    try:
        chunks_and_frozen_zones = frozen_zone_re.split(text)

        frozen_prefixes = ['']
        for chunk,frozen_suffix in zip(chunks_and_frozen_zones[0::2], chunks_and_frozen_zones[1::2]):
            frozen_prefixes = get_next_frozen_prefixes(chunk, frozen_prefixes, frozen_suffix)

        final_chunk = chunks_and_frozen_zones[len(chunks_and_frozen_zones) - 1]
        # we don't want a result like ['']
        result = [f for f in get_next_frozen_prefixes(final_chunk, frozen_prefixes) if f != '']

    except TimedOutExc as e:
        sys.stderr.write('\r\asciify warning: timed out for this input text:\r\n')
        sys.stderr.write(text)
        sys.stderr.write('\r\nreturning input text unchanged.\r\n')
        result = [text]
        pass
    except:
        result = [text]
        sys.stderr.write('\r\nasciify error: could not handle this input text:\r\n')
        sys.stderr.write(text)
        raise
    return result
