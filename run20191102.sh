#! /bin/bash

function finish() {
        echo "Error on line $1"
        exit 1
}

trap 'finish $LINENO' SIGINT SIGTERM ERR

./pfocr.py clear matches
./pfocr.py match -n stop -n nfkc -n deburr -m expand -m root -n swaps -n alphanumeric
./pfocr.py summarize
