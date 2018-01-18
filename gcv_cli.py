#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import argparse
from gcv import gcv

parser = argparse.ArgumentParser(
		description='''OCR an image.''')
parser.add_argument('filepath',
		type=str,
		help='file path to image')
args = parser.parse_args()
filepath = args.filepath

result = gcv(filepath=filepath, type='TEXT_DETECTION')
print(result)
