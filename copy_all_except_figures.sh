#!/usr/bin/env bash
# use this if you want to ocr a new batch of figures
# it copies everything except the papers and figures from the previous batch
# note that the papers table is only for the figures that are run.
# the other tables (xrefs, pmcs, are comprehensive and not specific to the previous batch.
# For example, pmcs includes _all_ PMC entries.

from_db="${1:-pfocr5}"
to_db="${2:-pfocr2018121717}"

echo "copying tables for fresh figure batch from $from_db to $to_db..."

psql "$from_db" -c \
"\copy (SELECT pmcid, pmid, journal, title, abstract, issn, eissn, year, volume, issue, page, doi, manuscript_id, release_date FROM pmcs ORDER BY pmcid) TO STDOUT" | \
psql "$to_db" -c "\copy pmcs (pmcid, pmid, journal, title, abstract, issn, eissn, year, volume, issue, page, doi, manuscript_id, release_date) FROM STDIN"

psql "$from_db" -c \
"\copy (SELECT id, xref FROM xrefs ORDER BY id, xref) TO STDOUT" | \
psql "$to_db" -c "\copy xrefs (id, xref) FROM STDIN"
psql "$to_db" -c "SELECT setval('xrefs_id_seq', (SELECT max(id) FROM xrefs));"

psql "$from_db" -c \
"\copy (SELECT xref FROM xrefs_wp_hs ORDER BY xref) TO STDOUT" | \
psql "$to_db" -c "\copy xrefs_wp_hs (xref) FROM STDIN"

psql "$from_db" -c \
"\copy (SELECT id, symbol FROM symbols ORDER BY id, symbol) TO STDOUT" | \
psql "$to_db" -c "\copy symbols (id, symbol) FROM STDIN"
psql "$to_db" -c "SELECT setval('symbols_id_seq', (SELECT max(id) FROM symbols));"

psql "$from_db" -c \
"\copy (SELECT symbol_id, xref_id, source FROM lexicon ORDER BY symbol_id, xref_id, source) TO STDOUT" | \
psql "$to_db" -c "\copy lexicon (symbol_id, xref_id, source) FROM STDIN"

psql "$from_db" -c \
"\copy (SELECT id, created, transforms FROM matchers ORDER BY id, created, transforms) TO STDOUT" | \
psql "$to_db" -c "\copy matchers (id, created, transforms) FROM STDIN"
psql "$to_db" -c "SELECT setval('matchers_id_seq', (SELECT max(id) FROM matchers));"

psql "$from_db" -c \
"\copy (SELECT id, created, engine, prepare_image, perform_ocr, hash FROM ocr_processors ORDER BY id, created, engine, prepare_image, perform_ocr, hash) TO STDOUT" | \
psql "$to_db" -c "\copy ocr_processors (id, created, engine, prepare_image, perform_ocr, hash) FROM STDIN"
psql "$to_db" -c "SELECT setval('ocr_processors_id_seq', (SELECT max(id) FROM ocr_processors));"
