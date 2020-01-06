images_dir="/home/pfocr/pmc/20181216/images"
for f in $(cat imagepaths.csv); do
	if [ ! -f "$images_dir"/"$f" ]; then
		base=$(basename "$f");
		# https://www.ncbi.nlm.nih.gov/pmc/articles/PMC6030103/bin/41418_2017_6_Fig6_HTML.jpg
		url="https://www.ncbi.nlm.nih.gov/pmc/articles/"$(echo "$base" | sed 's#__#/bin/#');
		#echo "curl $url > $f";
		curl "$url" > "$f";
	fi
done
