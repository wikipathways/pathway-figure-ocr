#!/usr/bin/env python3
# -*- coding: utf-8 -*-

# TODO: what does this file do?

import argparse
import json
import csv
import os
import psycopg2
import psycopg2.extras
import re
import sys

from get_pg_conn import get_pg_conn

from pathlib import Path, PurePath


def locate(db=None):
    conn = get_pg_conn(db=db)
    summary_cur = conn.cursor(cursor_factory=psycopg2.extras.DictCursor)
    stats_cur = conn.cursor(cursor_factory=psycopg2.extras.DictCursor)
    results_cur = conn.cursor(cursor_factory=psycopg2.extras.DictCursor)
    ocr_processors__figures_cur = conn.cursor(cursor_factory=psycopg2.extras.DictCursor)


    try:
#        results_query = '''
#        SELECT pmcid, figure_filepath, word, symbol, source, hgnc_symbol, xref as entrez, transforms_applied
#        FROM figures__xrefs
#        ORDER BY pmcid, figure_filepath, word;
#        '''
#        results_cur.execute(results_query)

        #SELECT ocr_processor_id, figure_id, jsonb_extract_path(result, 'textAnnotations', '0', 'description') AS description
        ocr_processors__figures_query = '''
        SELECT ocr_processor_id, figure_id, jsonb_extract_path(result, 'fullTextAnnotation') AS full_text_annotation
        FROM ocr_processors__figures ORDER BY ocr_processor_id, figure_id LIMIT 1;
        '''
        ocr_processors__figures_cur.execute(ocr_processors__figures_query)
        #print(result.keys)
        #print(ocr_processors__figures_cur)
        for row in ocr_processors__figures_cur:
            ocr_processor_id = row["ocr_processor_id"]
            print("ocr_processor_id: %s" % ocr_processor_id)
            figure_id = row["figure_id"]
            print("figure_id: %s" % figure_id)
            full_text_annotation = row["full_text_annotation"]
            print('full_text_annotation text')
            print(full_text_annotation["text"])
            # pages[0].blocks[0].paragraphs[0].words[0].symbols[0]
            #print(row)
            #print(type(row))
            #print(row.keys())
            #print(type(row[0]))
            for block in full_text_annotation["pages"][0]["blocks"]:
                for paragraph in block["paragraphs"]:
                    for word in paragraph["words"]:
                        word_text = ''
                        for symbol in word["symbols"]:
                            word_text += symbol["text"]
                        print("word: %s" % word_text)

#        results = []
#        for row in results_cur:
#            pmcid = row["pmcid"]
#            figure_filepath = row["figure_filepath"]
#            word = row["word"]
#            symbol = row["symbol"]
#            source = row["source"]
#            hgnc_symbol = row["hgnc_symbol"]
#            entrez = row["entrez"]
#            transforms_applied = row["transforms_applied"]
#
#            if figure_filepath != "":
#                results.append({
#                    "pmcid": pmcid,
#                    "figure": os.path.basename(figure_filepath),
#                    "word": word,
#                    "symbol": symbol,
#                    "source": source,
#                    "hgnc_symbol": hgnc_symbol,
#                    "entrez": entrez,
#                    "transforms_applied": transforms_applied
#                })
#
#        stats_query = '''
#        SELECT paper_count, nonwordless_paper_count, figure_count, nonwordless_figure_count, word_count_gross, word_count_unique, hit_count_gross, hit_count_unique, xref_count_gross, xref_count_unique, xref_not_in_wp_hs_count
#        FROM stats;
#        '''
#        stats_cur.execute(stats_query)
#            
#        # TODO are there any cases when the max ocr_processor_id value from match_attempts wouldn't be the ocr_processor we want to summarize?
#        summary_cur.execute("SELECT max(ocr_processor_id) FROM match_attempts;")
#        #summary_cur.execute("SELECT id FROM ocr_processors;")
#        ocr_processor_id = summary_cur.fetchone()[0]
#        summary_cur.execute("SELECT max(id) FROM ocr_processors;")
#        ocr_processor_id_alt = summary_cur.fetchone()[0]
#        if ocr_processor_id != ocr_processor_id_alt:
#            raise Exception("Error! ocr_processor_id mismatch in summarize.py: %s != %s" % (ocr_processor_id, ocr_processor_id_alt))
#
#        # TODO are there any cases when the max matcher_id value from match_attempts wouldn't be the matcher we want to summarize?
#        summary_cur.execute("SELECT max(matcher_id) FROM match_attempts;")
#        matcher_id = summary_cur.fetchone()[0]
#        summary_cur.execute("SELECT max(id) FROM matchers;")
#        matcher_id_alt = summary_cur.fetchone()[0]
#        if matcher_id != matcher_id_alt:
#            raise Exception("Error! matcher_id mismatch in summarize.py: %s != %s" % (matcher_id, matcher_id_alt))
#
#        for row in stats_cur:
#            paper_count = row["paper_count"]
#            nonwordless_paper_count = row["nonwordless_paper_count"]
#            figure_count = row["figure_count"]
#            nonwordless_figure_count = row["nonwordless_figure_count"]
#            word_count_gross = row["word_count_gross"]
#            word_count_unique = row["word_count_unique"]
#            hit_count_gross = row["hit_count_gross"]
#            hit_count_unique = row["hit_count_unique"]
#            xref_count_gross = row["xref_count_gross"]
#            xref_count_unique = row["xref_count_unique"]
#            xref_not_in_wp_hs_count = row["xref_not_in_wp_hs_count"]
#
#            summary_cur.execute("DELETE FROM summaries WHERE matcher_id=%s;", (matcher_id, ))
#            summary_cur.execute('''
#                    INSERT INTO summaries (matcher_id, ocr_processor_id, paper_count, nonwordless_paper_count, figure_count, nonwordless_figure_count, word_count_gross, word_count_unique, hit_count_gross, hit_count_unique, xref_count_gross, xref_count_unique, xref_not_in_wp_hs_count)
#                    VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s);''',
#                    (matcher_id, ocr_processor_id, paper_count, nonwordless_paper_count, figure_count, nonwordless_figure_count, word_count_gross, word_count_unique, hit_count_gross, hit_count_unique, xref_count_gross, xref_count_unique, xref_not_in_wp_hs_count)
#                    )
#
#        conn.commit()
#
#        with open('../outputs/results.tsv', 'w', newline='') as resultsfile:
#            fieldnames = ["pmcid", "figure", "word", "symbol", "source", "hgnc_symbol", "entrez", "transforms_applied"]
#            writer = csv.DictWriter(resultsfile, fieldnames=fieldnames, dialect='excel-tab')
#            writer.writeheader()
#            for result in results:
#                writer.writerow(result)
#
##        header_entries = ["pmcid", "figure", "word", "symbol", "source", "hgnc_symbol", "entrez", "transforms_applied"]
##        header_length = len(header_entries)
##        output_rows = [",".join(header_entries)]
##        for result in results:
##            row_entries = [result["pmcid"], result["figure"], result["word"], result["symbol"], result["source"], result["hgnc_symbol"], result["entrez"], result["transforms_applied"]]
##            row_length = len(row_entries)
##            if row_length != header_length: 
##                raise Exception("Error! row length %s doesn't match header length %s" % (row_length, header_length), '\n', ",".join(row_entries))
##            output_rows.append(",".join(row_entries))
##
##        with open("../outputs/results.csv", "a+") as resultsfile:
##            resultsfile.write('\n'.join(output_rows))

    except(psycopg2.DatabaseError) as e:
        print('Error %s' % psycopg2.DatabaseError)
        print('Error %s' % e)
        sys.exit(1)
        
    finally:
        if conn:
            conn.close()

if __name__ == '__main__':
    # python pfocr/locate.py --db "pfocr2018121717"
    parser = argparse.ArgumentParser(
        description='''Locate.''')
    parser.add_argument('--db',
                        type=str,
                        help='Database to query, e.g., pfocr2018121717')
    args = parser.parse_args()
    locate(db=args.db)
