psql pfocr5 -c \
"\copy (SELECT id, xref FROM xrefs ORDER BY id, xref) TO STDOUT" | \
psql pfocr2018121717 -c "\copy xrefs (id, xref) FROM STDIN"
psql pfocr2018121717 -c "SELECT setval('xrefs_id_seq', (SELECT max(id) FROM xrefs));"

psql pfocr5 -c \
"\copy (SELECT xref FROM xrefs_wp_hs ORDER BY xref) TO STDOUT" | \
psql pfocr2018121717 -c "\copy xrefs_wp_hs (xref) FROM STDIN"

psql pfocr5 -c \
"\copy (SELECT id, symbol FROM symbols ORDER BY id, symbol) TO STDOUT" | \
psql pfocr2018121717 -c "\copy symbols (id, symbol) FROM STDIN"
psql pfocr2018121717 -c "SELECT setval('symbols_id_seq', (SELECT max(id) FROM symbols));"

psql pfocr5 -c \
"\copy (SELECT symbol_id, xref_id, source FROM lexicon ORDER BY symbol_id, xref_id, source) TO STDOUT" | \
psql pfocr2018121717 -c "\copy lexicon (symbol_id, xref_id, source) FROM STDIN"

psql pfocr5 -c \
"\copy (SELECT id, created, transforms FROM matchers ORDER BY id, created, transforms) TO STDOUT" | \
psql pfocr2018121717 -c "\copy matchers (id, created, transforms) FROM STDIN"
psql pfocr2018121717 -c "SELECT setval('matchers_id_seq', (SELECT max(id) FROM matchers));"

psql pfocr5 -c \
"\copy (SELECT id, created, engine, prepare_image, perform_ocr, hash FROM ocr_processors ORDER BY id, created, engine, prepare_image, perform_ocr, hash) TO STDOUT" | \
psql pfocr2018121717 -c "\copy ocr_processors (id, created, engine, prepare_image, perform_ocr, hash) FROM STDIN"
psql pfocr2018121717 -c "SELECT setval('ocr_processors_id_seq', (SELECT max(id) FROM ocr_processors));"
