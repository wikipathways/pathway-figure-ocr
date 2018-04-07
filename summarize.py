#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import json
import os
import psycopg2
import psycopg2.extras
import re
import transforms

from get_conn import get_conn

def summarize(args):
    conn = get_conn()
    summary_cur = conn.cursor(cursor_factory=psycopg2.extras.DictCursor)
    stats_cur = conn.cursor(cursor_factory=psycopg2.extras.DictCursor)
    results_cur = conn.cursor(cursor_factory=psycopg2.extras.DictCursor)


    try:
        results_query = '''
        SELECT figure_filepath, word, transformed_word, xref, source, transforms_applied AS transform
        FROM figures__xrefs
        GROUP BY figure_filepath, word, transformed_word, xref, source, transforms_applied;
        '''
        results_cur.execute(results_query)

        results = []
        latest_figure_filepath = ""
        latest_transformed_word = ""
        latest_xref = ""
        running_transforms = []
        for row in results_cur:
            figure_filepath = row["figure_filepath"]
            word = row["word"]
            transformed_word = row["transformed_word"]
            xref = row["xref"]
            transform = row["transform"]

            if figure_filepath != latest_figure_filepath and transformed_word != latest_transformed_word:
                if latest_figure_filepath != "":
                    results.append({
                        "figure": "https://dev.wikipathways.org/pfocr/" + os.path.basename(latest_figure_filepath),
                        "word": word,
                        "transformed_word": latest_transformed_word,
                        "xref": latest_xref,
                        "transforms": running_transforms
                    })
                latest_figure_filepath = figure_filepath
                latest_transformed_word = transformed_word
                latest_xref = xref
                running_transforms = [transform]
            else:
                running_transforms.append(transform)

        stats_query = '''
        SELECT paper_count, figure_count, word_count_gross, word_count_unique, hit_count_gross, hit_count_unique, xref_count_gross, xref_count_unique
        FROM stats;
        '''
        stats_cur.execute(stats_query)

        for row in stats_cur:
            paper_count = row["paper_count"]
            figure_count = row["figure_count"]
            word_count_gross = row["word_count_gross"]
            word_count_unique = row["word_count_unique"]
            hit_count_gross = row["hit_count_gross"]
            hit_count_unique = row["hit_count_unique"]
            xref_count_gross = row["xref_count_gross"]
            xref_count_unique = row["xref_count_unique"]
            
            summary_cur.execute("DELETE FROM summaries WHERE matcher_id=(SELECT id FROM matchers);")
            summary_cur.execute('''
                    INSERT INTO summaries (matcher_id, ocr_processor_id, paper_count, figure_count, word_count_gross, word_count_unique, hit_count_gross, hit_count_unique, xref_count_gross, xref_count_unique)
                    VALUES ((SELECT id FROM matchers), (SELECT id FROM ocr_processors), %s, %s, %s, %s, %s, %s, %s, %s);''',
                    (paper_count, figure_count, word_count_gross, word_count_unique, hit_count_gross, hit_count_unique, xref_count_gross, xref_count_unique)
                    )

        conn.commit()

        output_rows = ["\t".join(["figure", "word", "transformed_word", "xref", "transforms"])]
        for result in results:
            output_rows.append("\t".join([result["figure"], result["word"], result["transformed_word"], result["xref"], ",".join(result["transforms"])]))

        with open("./results.tsv", "a+") as resultsfile:
            resultsfile.write('\n'.join(output_rows))

    except(psycopg2.DatabaseError) as e:
        print('Error %s' % psycopg2.DatabaseError)
        print('Error %s' % e)
        sys.exit(1)
        
    finally:
        if conn:
            conn.close()
