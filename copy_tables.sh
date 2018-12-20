#!/usr/bin/env bash
# use this if you want to re-run post-processing on a batch of figures that has already been OCRed.

# see https://stackoverflow.com/a/246128/5354298
get_script_dir() { echo "$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"; }
SCRIPT_DIR=$(get_script_dir)

from_db="${1:-pfocr5}"
to_db="${2:-pfocr2018121717}"

echo "copying tables for post-processing re-run from $from_db to $to_db..."

bash "$SCRIPT_DIR/copy_all_except_figures.sh" "$from_db" "$to_db"

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
"\copy (SELECT id, pmcid, title, url, abstract, date, journal FROM papers ORDER BY id, pmcid, title, url, abstract, date, journal) TO STDOUT" | \
psql "$to_db" -c "\copy papers (id, pmcid, title, url, abstract, date, journal) FROM STDIN"
psql "$to_db" -c "SELECT setval('papers_id_seq', (SELECT max(id) FROM papers));"

psql "$from_db" -c \
"\copy (SELECT id, paper_id, filepath, figure_number, caption FROM figures ORDER BY id, paper_id, filepath, figure_number, caption) TO STDOUT" | \
psql "$to_db" -c "\copy figures (id, paper_id, filepath, figure_number, caption) FROM STDIN"
psql "$to_db" -c "SELECT setval('figures_id_seq', (SELECT max(id) FROM figures));"

psql "$from_db" -c \
"\copy (SELECT ocr_processor_id, figure_id, result FROM ocr_processors__figures ORDER BY ocr_processor_id, figure_id, result) TO STDOUT" | \
psql "$to_db" -c "\copy ocr_processors__figures (ocr_processor_id, figure_id, result) FROM STDIN"

#match_attempts_columns='id, ocr_processor_id, matcher_id, transforms_applied, figure_id, word, transformed_word_id';
#psql "$from_db" -c \
#"\copy (SELECT $match_attempts_columns FROM match_attempts ORDER BY $match_attempts_columns) TO STDOUT" | \
#psql "$to_db" -c "\copy match_attempts ($match_attempts_columns) FROM STDIN"
#psql "$to_db" -c "SELECT setval('match_attempts_id_seq', (SELECT max(id) FROM match_attempts));"

summaries_columns='matcher_id, ocr_processor_id, timestamp, paper_count, nonwordless_paper_count, figure_count, nonwordless_figure_count, word_count_gross, word_count_unique, hit_count_gross, hit_count_unique, xref_count_gross, xref_count_unique, xref_not_in_wp_hs_count';
psql "$from_db" -c \
"\copy (SELECT $summaries_columns FROM summaries ORDER BY $summaries_columns) TO STDOUT" | \
psql "$to_db" -c "\copy summaries ($summaries_columns) FROM STDIN"
