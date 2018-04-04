psql pfocr -c \
"\copy (SELECT id, xref FROM xrefs ORDER BY id, xref) TO STDOUT" | \
psql pfocr2 -c "\copy xrefs (id, xref) FROM STDIN"

psql pfocr -c \
"\copy (SELECT xref FROM xrefs_wp_hs ORDER BY xref) TO STDOUT" | \
psql pfocr2 -c "\copy xrefs_wp_hs (xref) FROM STDIN"

psql pfocr -c \
"\copy (SELECT id, symbol FROM symbols ORDER BY id, symbol) TO STDOUT" | \
psql pfocr2 -c "\copy symbols (id, symbol) FROM STDIN"

psql pfocr -c \
"\copy (SELECT symbol_id, xref_id, source FROM lexicon ORDER BY symbol_id, xref_id, source) TO STDOUT" | \
psql pfocr2 -c "\copy lexicon (symbol_id, xref_id, source) FROM STDIN"

psql pfocr -c \
"\copy (SELECT id, pmcid, title, url, abstract, date, journal FROM papers ORDER BY id, pmcid, title, url, abstract, date, journal) TO STDOUT" | \
psql pfocr2 -c "\copy papers (id, pmcid, title, url, abstract, date, journal) FROM STDIN"

psql pfocr -c \
"\copy (SELECT id, paper_id, filepath, figure_number, caption FROM figures ORDER BY id, paper_id, filepath, figure_number, caption) TO STDOUT" | \
psql pfocr2 -c "\copy figures (id, paper_id, filepath, figure_number, caption) FROM STDIN"

psql pfocr -c \
"\copy (SELECT id, engine, prepare_image, perform_ocr, hash FROM ocr_processors ORDER BY id, engine, prepare_image, perform_ocr, hash) TO STDOUT" | \
psql pfocr2 -c "\copy ocr_processors (id, engine, prepare_image, perform_ocr, hash) FROM STDIN"

psql pfocr -c \
"\copy (SELECT ocr_processor_id, figure_id, result FROM ocr_processors__figures ORDER BY ocr_processor_id, figure_id, result) TO STDOUT" | \
psql pfocr2 -c "\copy ocr_processors__figures (ocr_processor_id, figure_id, result) FROM STDIN"
