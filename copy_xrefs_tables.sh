#!/bin/bash

function finish() {
        echo "Error on line $1"
        exit 1
}

trap 'finish $LINENO' SIGINT SIGTERM ERR

src_db="pfocr2018121717"
target_db="pfocr20191102"

pg_dump -a -t organism_names "$src_db" | psql "$target_db"
pg_dump -a -t xrefs "$src_db" | psql "$target_db"
pg_dump -a -t symbols "$src_db" | psql "$target_db"
pg_dump -a -t lexicon "$src_db" | psql "$target_db"
