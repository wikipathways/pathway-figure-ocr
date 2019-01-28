#! /bin/bash

function finish {
  echo "Error on line $1"
  exit 1
}

trap 'finish $LINENO' SIGINT SIGTERM ERR

results="./outputs/results.tsv";
headless="./outputs/headless.tsv";
sample="./outputs/co_check.tsv";
papers="./outputs/papers.tsv"

# if papers weren't specified in previous run
if [ ! -f "$papers" ]; then
  echo "Cannot generate a check dataset when $papers doesn't exist!"
  exit 1
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
rm "$headless" "$papers"
