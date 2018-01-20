#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import argparse
import json
from pathlib import Path
import re

from ocr_pmc import ocr_pmc
from gcv import gcv


parser = argparse.ArgumentParser(
		description='''Run GCV on PMC figures and save results to database.''')
parser.add_argument('--start',
		type=int,
		help='start of figures to process')
parser.add_argument('--end',
		type=int,
		help='end of figures to process')
args = parser.parse_args()
start = args.start
end = args.end

def prepare_image(filepath):
    return filepath

def do_gcv(prepared_filepath):
    gcv_result_raw = gcv(filepath=prepared_filepath, type='TEXT_DETECTION')
    if len(gcv_result_raw['responses']) != 1:
        print(gcv_result_raw)
        raise ValueError("""
            gcv_pmc.py expects the JSON result from GCV will always be {"responses": [...]},
            with "responses" having just a single value, but
            the result above indicates that assumption was incorrect.
            """)
    return gcv_result_raw['responses'][0]

ocr_pmc(prepare_image, do_gcv, "gcv", start, end)
