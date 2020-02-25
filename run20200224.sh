#!/usr/bin/env bash

function finish() {
        echo "Error on line $1"
        exit 1
}

trap 'finish $LINENO' SIGINT SIGTERM ERR

## DATABASE

#echo 'pfocr20191102_93k' > ./CURRENT_DB
#./pfocr.py db_copy pfocr20200224
#echo 'copied'
#echo ''

## LOAD FIGURES

#./pfocr.py load_figures ../data/images_ocred_20200224
#echo 'loaded'
#echo ''

## OCR

./pfocr.py ocr gcv --preprocessor noop

## MATCH and SUMMARIZE

./pfocr.py clear matches
./pfocr.py match -n stop -n nfkc -n deburr -m expand -m root -n swaps -n alphanumeric
echo 'matched'
echo ''

./pfocr.py summarize
echo 'summarized'
echo ''
