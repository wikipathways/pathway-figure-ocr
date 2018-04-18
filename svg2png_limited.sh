#! /bin/bash

image_dir="../wp/20180417"
for f in $image_dir/svg/*.svg
do
	echo "$f"
	png=$image_dir"/png/"$(basename "$f" | sed 's/\.svg/.png/')
	echo "$png"

	if [ ! -f "$png" ]; then
		inkscape -z -e "$png" -d 382 "$f"
	fi

	if [[ $(find "$png" -type f -size +5M 2>/dev/null) ]]; then
		inkscape -z -e "$png" -d 150 "$f"
	fi
done
