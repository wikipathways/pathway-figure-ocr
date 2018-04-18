psql pfocr5 -c \
"\copy (SELECT id, xref FROM xrefs ORDER BY id, xref) TO STDOUT" | \
psql pfocr -c "\copy xrefs (id, xref) FROM STDIN"
psql pfocr -c "SELECT setval('xrefs_id_seq', (SELECT max(id) FROM xrefs));"

psql pfocr5 -c \
"\copy (SELECT xref FROM xrefs_wp_hs ORDER BY xref) TO STDOUT" | \
psql pfocr -c "\copy xrefs_wp_hs (xref) FROM STDIN"

psql pfocr5 -c \
"\copy (SELECT id, symbol FROM symbols ORDER BY id, symbol) TO STDOUT" | \
psql pfocr -c "\copy symbols (id, symbol) FROM STDIN"
psql pfocr -c "SELECT setval('symbols_id_seq', (SELECT max(id) FROM symbols));"

psql pfocr5 -c \
"\copy (SELECT symbol_id, xref_id, source FROM lexicon ORDER BY symbol_id, xref_id, source) TO STDOUT" | \
psql pfocr -c "\copy lexicon (symbol_id, xref_id, source) FROM STDIN"

psql pfocr5 -c \
"\copy (SELECT id, pmcid, title, url, abstract, date, journal FROM papers ORDER BY id, pmcid, title, url, abstract, date, journal) TO STDOUT" | \
psql pfocr -c "\copy papers (id, pmcid, title, url, abstract, date, journal) FROM STDIN"
psql pfocr -c "SELECT setval('papers_id_seq', (SELECT max(id) FROM papers));"

psql pfocr5 -c \
"\copy (SELECT id, paper_id, filepath, figure_number, caption FROM figures ORDER BY id, paper_id, filepath, figure_number, caption) TO STDOUT" | \
psql pfocr -c "\copy figures (id, paper_id, filepath, figure_number, caption) FROM STDIN"
psql pfocr -c "SELECT setval('figures_id_seq', (SELECT max(id) FROM figures));"

psql pfocr5 -c \
"\copy (SELECT id, created, transforms FROM matchers ORDER BY id, created, transforms) TO STDOUT" | \
psql pfocr -c "\copy matchers (id, created, transforms) FROM STDIN"
psql pfocr -c "SELECT setval('matchers_id_seq', (SELECT max(id) FROM matchers));"

psql pfocr5 -c \
"\copy (SELECT id, created, engine, prepare_image, perform_ocr, hash FROM ocr_processors ORDER BY id, created, engine, prepare_image, perform_ocr, hash) TO STDOUT" | \
psql pfocr -c "\copy ocr_processors (id, created, engine, prepare_image, perform_ocr, hash) FROM STDIN"
psql pfocr -c "SELECT setval('ocr_processors_id_seq', (SELECT max(id) FROM ocr_processors));"

psql pfocr5 -c \
"\copy (SELECT ocr_processor_id, figure_id, result FROM ocr_processors__figures ORDER BY ocr_processor_id, figure_id, result) TO STDOUT" | \
psql pfocr -c "\copy ocr_processors__figures (ocr_processor_id, figure_id, result) FROM STDIN"

#match_attempts_columns='id, ocr_processor_id, matcher_id, transforms_applied, figure_id, word, transformed_word_id';
#psql pfocr5 -c \
#"\copy (SELECT $match_attempts_columns FROM match_attempts ORDER BY $match_attempts_columns) TO STDOUT" | \
#psql pfocr -c "\copy match_attempts ($match_attempts_columns) FROM STDIN"
#psql pfocr -c "SELECT setval('match_attempts_id_seq', (SELECT max(id) FROM match_attempts));"

summaries_columns='matcher_id, ocr_processor_id, timestamp, paper_count, nonwordless_paper_count, figure_count, nonwordless_figure_count, word_count_gross, word_count_unique, hit_count_gross, hit_count_unique, xref_count_gross, xref_count_unique, xref_not_in_wp_hs_count';
psql pfocr5 -c \
"\copy (SELECT $summaries_columns FROM summaries ORDER BY $summaries_columns) TO STDOUT" | \
psql pfocr -c "\copy summaries ($summaries_columns) FROM STDIN"
