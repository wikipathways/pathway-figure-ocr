#! /bin/bash

function finish() {
        echo "Error on line $1"
        exit 1
}

trap 'finish $LINENO' SIGINT SIGTERM ERR

cd pfocr
#./pfocr.py db_copy pfocr2018121717 pfocr2018121717subset
#./pfocr.py clear pfocr2018121717subset matches

./pfocr.py match pfocr2018121717subset /home/pfocr/pathway-figure-ocr/outputs -n stop -n nfkc -n deburr -m expand -m root -n swaps -n alphanumeric

#./pfocr.py summarize

# Generate curated optimization datasets
#bash ./gen_co_check.sh
#bash ./gen_co_next.sh

cd ..
