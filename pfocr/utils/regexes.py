#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import re

# Characters indicating we should split
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
always_split_re = re.compile('[' + always_split_pattern + ']+')

basic_latin_pattern = '\u0020-\u007F'

# alphanumeric includes underscore
latin_letter_number_pattern = '[A-Za-z0-9]'

# We want the split transformation to pass these through unchanged so that expand can handle them
frozen_zone_re_strings = [
        # NOTE: this one needs to be before the one that follows it.
        '\d(?:\,\s?\d)*\,?\s(?:and|or|&)\s\d',
        '\d+(?:\s?\D\s?\d+)+',

        # WNT3 or 4
        # ABC or DEF
        '\s(?:and|or|&)\s',

        # TODO: should the following use 2 or 3?
        '\d{2,}',

        # TODO should we treat space as a frozen zone?
        #'\s'
        ]
frozen_zone_re_string_concatenated = '((?:' + ')|(?:'.join(frozen_zone_re_strings) + '))'
frozen_zone_re = re.compile(frozen_zone_re_string_concatenated)
