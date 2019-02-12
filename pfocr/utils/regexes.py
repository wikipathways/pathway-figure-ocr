#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import re

always_split_pattern = '\n\r\f\v\u2190-\u2199'
always_split_re = re.compile('[' + always_split_pattern + ']+')

basic_latin_pattern = '\u0020-\u007F'

frozen_zone_re_strings = [
        # NOTE: this one needs to be before the one that follows it.
        '\d(?:\,\s?\d)*\,?\s(?:and|or|&)\s\d',
        '\d+(?:\s?\D\s?\d+)+',
        '\s(?:and|or|&)\s',
        # TODO: should this be 2 or 3?
        '\d{2,}'
        # TODO should we treat space as a frozen zone?
        #'\s'
        ]
frozen_zone_re_string_concatenated = '((?:' + ')|(?:'.join(frozen_zone_re_strings) + '))'
frozen_zone_re = re.compile(frozen_zone_re_string_concatenated)
