import base64
import json
from pathlib import Path
import requests

p = Path('/home/pfocr/gcv/API_KEY')
API_KEY = p.read_text().strip()
URL = 'https://vision.googleapis.com/v1/images:annotate?key=' + API_KEY

def gcv(
        filepath=None,
        type=None,
        debug=False):
    with open(filepath, "rb") as image_file:
            image_b64 = base64.b64encode(image_file.read()).decode('utf8')
            body = json.dumps({
                    "requests": [{
                            "image": {"content": image_b64},
                            "features": [{"type": type}]
                            }]
                    })
            headers = {
                    'Content-Type': 'application/json',
            }
            r = requests.post(URL, data=body, headers=headers)
            return r.json()
