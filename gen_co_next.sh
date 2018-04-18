#! /bin/bash

function finish {
  # Your cleanup code here
  echo "Error on line $1"
  exit 1
}

trap 'finish $LINENO' SIGINT SIGTERM ERR

results="./outputs/results.tsv";
headless="./outputs/headless.tsv";
sample="./outputs/co_next.tsv";
papers="./outputs/papers.tsv"

tail -n +1 "$results" | cut -f 1 | sort | uniq | shuf -n 32 > "$papers"

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
