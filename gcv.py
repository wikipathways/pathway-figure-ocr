#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import argparse
import base64
import json
from pathlib import Path
import requests

parser = argparse.ArgumentParser(
		description='''OCR an image.''')
parser.add_argument('filepath',
		type=str,
		help='file path to image')
args = parser.parse_args()
filepath = args.filepath

p = Path('/home/pfocr/gcv/API_KEY')
API_KEY = p.read_text().strip()
"""
print('API_KEY')
print(API_KEY)
print('API_KEY')
"""

TYPE = 'TEXT_DETECTION'
URL = 'https://vision.googleapis.com/v1/images:annotate?key=' + API_KEY

with open(filepath, "rb") as image_file:
	image_b64 = base64.b64encode(image_file.read()).decode('utf8')
	body = json.dumps({
		"requests": [{
			"image": {"content": image_b64},
			"features": [{"type": TYPE}]
			}]
		})
	headers = {
		'Content-Type': 'application/json',
	}
	r = requests.post(URL, data=body, headers=headers)
	print(r.json())
