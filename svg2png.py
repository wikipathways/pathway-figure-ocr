#!/usr/bin/env python3
# -*- coding: utf-8 -*-

from pathlib import Path
from wand.image import Image
import glob

image_dir = "/home/pfocr/wp/20180417/"
for f in glob.glob(image_dir + "svg/*.svg")[0:1]:
    print('Processing %s' % f)
    stem = Path(f).stem
    with Image(filename=f, resolution=600) as img:
        print('svg resolution')
        print(img.resolution)
        with img.convert('png') as converted:
            print('converted resolution')
            print(converted.resolution)
            converted.save(filename=image_dir + stem + '.png')
