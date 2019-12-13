#! /bin/bash

function finish() {
        echo "Error on line $1"
        exit 1
}

trap 'finish $LINENO' SIGINT SIGTERM ERR

src_dir="20191102"
template_db="pfocr20191102_template"
new_db=pfocr"$src_dir"

./pfocr/pfocr.py db_copy "$template_db" "$new_db"
./pfocr/pfocr.py clear "$new_db" matches
./pfocr/pfocr.py clear "$new_db" figures
./pfocr/pfocr.py load_figures "$new_db" ../pmc/"$src_dir"/images/
#./pfocr/pfocr.py ocr "$new_db" gcv --preprocessor noop
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

#python -u ./pfocr/pfocr.py match pfocr20190215 ./output20190215 -n stop -n nfkc -n deburr -m expand -m root -n swaps -n alphanumeric

#python -u ./pfocr/pfocr.py summarize pfocr20190215

# Generate curated optimization datasets
#bash ./gen_co_check.sh
#bash ./gen_co_next.sh
