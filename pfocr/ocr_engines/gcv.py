#!/usr/bin/env python3
# -*- coding: utf-8 -*-

# See also
# https://github.com/GoogleCloudPlatform/python-docs-samples/blob/master/vision/cloud-client/detect/detect.py#L272

import argparse
import base64
import json
from pathlib import Path
import requests

p = Path('/home/pfocr/gcv/API_KEY')
API_KEY = p.read_text().strip()
URL = "https://vision.googleapis.com/v1/images:annotate?key=%s" % (API_KEY)


def gcv_raw(
        filepath=None,
        type=None,
        debug=False):
    with open(filepath, "rb") as image_file:
        image_b64 = base64.b64encode(image_file.read()).decode('utf8')
        body = json.dumps({
            "requests": [{
                "image": {"content": image_b64},
                "imageContext": {
                    "languageHints": ["en"]
                    #"languageHints": ["en", "el"]
                },
                "features": [{"type": type}]
            }]
        })
        headers = {
            'Content-Type': 'application/json',
        }
        r = requests.post(URL, data=body, headers=headers)
        return r.json()


def gcv(prepared_filepath):
    gcv_result_raw = gcv_raw(
            filepath=prepared_filepath,
            type='TEXT_DETECTION'
            )
    if len(gcv_result_raw['responses']) != 1:
        print(gcv_result_raw)
        raise ValueError("""
            gcv.py expects the JSON result from GCV will always be {"responses": [...]},
            with "responses" having just a single value, but
            the result above indicates that assumption was incorrect.
            """)
    return gcv_result_raw['responses'][0]


if __name__ == "__main__":
    parser = argparse.ArgumentParser(
        description='''OCR an image.''')
    parser.add_argument('filepath',
                        type=str,
                        help='file path to image')
    args = parser.parse_args()
    filepath = args.filepath

    result = gcv_raw(
            filepath=filepath,
            type='TEXT_DETECTION'
            )
    print(result)
