#! /bin/bash

image_dir="../wp/20180417"
for f in $image_dir/svg/*.svg
do
	echo "$f"
	png=$image_dir"/png/"$(basename "$f" | sed 's/\.svg/.png/')
	echo "$png"
	inkscape -z -e "$png" -d 382 "$f"
done
