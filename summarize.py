#! /usr/bin/env nix-shell
#! nix-shell -i python3 -p 'python36.withPackages(ps: with ps; [ psycopg2 requests dill ])' -p postgresql
# -*- coding: utf-8 -*-

import json
import os
import psycopg2
import psycopg2.extras
import re
import sys

from get_conn import get_conn

def summarize(args):
    conn = get_conn()
    summary_cur = conn.cursor(cursor_factory=psycopg2.extras.DictCursor)
    stats_cur = conn.cursor(cursor_factory=psycopg2.extras.DictCursor)
    results_cur = conn.cursor(cursor_factory=psycopg2.extras.DictCursor)


    try:
        results_query = '''
        SELECT pmcid, figure_filepath, word, symbol, xref as entrez, source, transforms_applied
        FROM figures__xrefs
        ORDER BY pmcid, figure_filepath, word;
        '''
        results_cur.execute(results_query)

        results = []
        for row in results_cur:
            pmcid = row["pmcid"]
            figure_filepath = row["figure_filepath"]
            word = row["word"]
            symbol = row["symbol"]
            entrez = row["entrez"]
            transforms_applied = row["transforms_applied"]

            if figure_filepath != "":
                results.append({
                    "pmcid": pmcid,
                    "figure": "https://dev.wikipathways.org/pfocr/" + os.path.basename(figure_filepath),
                    "word": word,
                    "symbol": symbol,
                    "entrez": entrez,
                    "transforms_applied": transforms_applied
                })

        stats_query = '''
        SELECT paper_count, nonwordless_paper_count, figure_count, nonwordless_figure_count, word_count_gross, word_count_unique, hit_count_gross, hit_count_unique, xref_count_gross, xref_count_unique, xref_not_in_wp_hs_count
        FROM stats;
        '''
        stats_cur.execute(stats_query)
            
        # TODO are there any cases when the max ocr_processor_id value from match_attempts wouldn't be the ocr_processor we want to summarize?
        summary_cur.execute("SELECT max(ocr_processor_id) FROM match_attempts;")
        #summary_cur.execute("SELECT id FROM ocr_processors;")
        ocr_processor_id = summary_cur.fetchone()[0]
        summary_cur.execute("SELECT max(id) FROM ocr_processors;")
        ocr_processor_id_alt = summary_cur.fetchone()[0]
        if ocr_processor_id != ocr_processor_id_alt:
            raise Exception("Error! ocr_processor_id mismatch in summarize.py: %s != %s" % (ocr_processor_id, ocr_processor_id_alt))

        # TODO are there any cases when the max matcher_id value from match_attempts wouldn't be the matcher we want to summarize?
        summary_cur.execute("SELECT max(matcher_id) FROM match_attempts;")
        matcher_id = summary_cur.fetchone()[0]
        summary_cur.execute("SELECT max(id) FROM matchers;")
        matcher_id_alt = summary_cur.fetchone()[0]
        if matcher_id != matcher_id_alt:
            raise Exception("Error! matcher_id mismatch in summarize.py: %s != %s" % (matcher_id, matcher_id_alt))

        for row in stats_cur:
            paper_count = row["paper_count"]
            nonwordless_paper_count = row["nonwordless_paper_count"]
            figure_count = row["figure_count"]
            nonwordless_figure_count = row["nonwordless_figure_count"]
            word_count_gross = row["word_count_gross"]
            word_count_unique = row["word_count_unique"]
            hit_count_gross = row["hit_count_gross"]
            hit_count_unique = row["hit_count_unique"]
            xref_count_gross = row["xref_count_gross"]
            xref_count_unique = row["xref_count_unique"]
            xref_not_in_wp_hs_count = row["xref_not_in_wp_hs_count"]

            summary_cur.execute("DELETE FROM summaries WHERE matcher_id=%s;", (matcher_id, ))
            summary_cur.execute('''
                    INSERT INTO summaries (matcher_id, ocr_processor_id, paper_count, nonwordless_paper_count, figure_count, nonwordless_figure_count, word_count_gross, word_count_unique, hit_count_gross, hit_count_unique, xref_count_gross, xref_count_unique, xref_not_in_wp_hs_count)
                    VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s);''',
                    (matcher_id, ocr_processor_id, paper_count, nonwordless_paper_count, figure_count, nonwordless_figure_count, word_count_gross, word_count_unique, hit_count_gross, hit_count_unique, xref_count_gross, xref_count_unique, xref_not_in_wp_hs_count)
                    )

        conn.commit()

        output_rows = ["\t".join(["pmcid", "figure", "word", "symbol", "entrez", "transforms_applied"])]
        for result in results:
            output_rows.append("\t".join([result["pmcid"], result["figure"], result["word"], result["symbol"], result["entrez"], result["transforms_applied"]]))

        with open("./results.tsv", "a+") as resultsfile:
            resultsfile.write('\n'.join(output_rows))

    except(psycopg2.DatabaseError) as e:
        print('Error %s' % psycopg2.DatabaseError)
        print('Error %s' % e)
        sys.exit(1)
        
    finally:
        if conn:
            conn.close()
