#! /bin/bash

function finish {
  # Your cleanup code here
  echo "Error on line $1"
  exit 1
}

trap 'finish $LINENO' SIGINT SIGTERM ERR

./pfocr.py clear matches;
#./pfocr.py match -n stop -n nfkc -n upper -n swaps -n deburr -n alphanumeric -m root -m one_to_I;
#./pfocr.py match -n stop -n nfkc -n upper -m root -n swaps -n deburr -n alphanumeric -m one_to_I;
#./pfocr.py match -n stop -n nfkc -n upper -n swaps -n deburr -n alphanumeric -m one_to_I -m root;
#./pfocr.py match -n stop -n nfkc -m expand -n stop -n nfkc -n upper;
#./pfocr.py match -n stop -n nfkc -m expand -n stop -n nfkc -n deburr -n upper;
#./pfocr.py match -n stop -n nfkc -m expand -n stop -n nfkc -n upper -n swaps -n deburr -n alphanumeric -m root -m one_to_I;

# Note: upper messes with alphanumeric sometimes, e.g. NF-KB1
#./pfocr.py match -n stop -m expand -n stop -m root -n alphanumeric;
# Note: need a pass though to upper without root to avoid missing things like Ras
#./pfocr.py match -n stop -m expand -n stop -n upper -n swaps -n alphanumeric ;
#./pfocr.py match -n stop -n nfkc -n deburr -m expand -n stop -m root -n upper -n swaps -n alphanumeric;

./pfocr.py match -n stop -n nfkc -n deburr -m expand -m root -n swaps -n alphanumeric;

./pfocr.py summarize

results="./results.tsv";
headless="./headless.tsv";
sample="./sample.tsv";
papers="./papers.tsv"

# if papers haven't already been selected
if [ ! -f "$papers" ]; then
	tail -n +1 "$results" | cut -f 1 | sort | uniq | shuf -n 32 > "$papers"
fi

rm -rf "$headless";
touch "$headless";

rm -rf "$sample";
touch "$sample";

while read -r paper; do
	grep -P "^""$paper" "$results" >> "$headless";
done < "$papers"

head -n 1 "$results" > "$sample"
sort "$headless" >> "$sample"
rm "$headless"
