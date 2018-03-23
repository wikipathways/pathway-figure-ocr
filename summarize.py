#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import json
import os
import psycopg2
import psycopg2.extras
import re
import transforms

def summarize(args):
    conn = psycopg2.connect("dbname=pfocr")
    summary_cur = conn.cursor(cursor_factory=psycopg2.extras.DictCursor)

    try:
        #SELECT figure_filepath, word, xref, jsonb_extract_path_text(jsonb_array_elements(transforms), 'name') AS transform
        summary_query = '''
        SELECT figure_filepath, word, xref, jsonb_array_elements(transforms) AS transform
        FROM figures__xrefs
        GROUP BY figure_filepath, word, xref, transforms;
        '''
        summary_cur.execute(summary_query)

        results = []
        latest_figure_filepath = ""
        latest_word = ""
        latest_xref = ""
        running_transforms = []
        for s in summary_cur:
            figure_filepath = s["figure_filepath"]
            word = s["word"]
            xref = s["xref"]
            transform = s["transform"]

            if figure_filepath != latest_figure_filepath and word != latest_word:
                if latest_figure_filepath != "":
                    results.append({
                        "figure": "https://dev.wikipathways.org/pfocr/" + os.path.basename(latest_figure_filepath),
                        "word": latest_word,
                        "xref": latest_xref,
                        "transforms": running_transforms
                    })
                latest_figure_filepath = figure_filepath
                latest_word = word
                latest_xref = xref
                running_transforms = [transform]
            else:
                running_transforms.append(transform)

        conn.commit()

        output_rows = ["\t".join(["figure", "word", "xref", "transforms"])]
        for result in results:
            output_rows.append("\t".join([result["figure"], result["word"], result["xref"], ",".join(result["transforms"])]))

        with open("./results.tsv", "a+") as resultsfile:
            resultsfile.write('\n'.join(output_rows))

    except(psycopg2.DatabaseError) as e:
        print('Error %s' % psycopg2.DatabaseError)
        print('Error %s' % e)
        sys.exit(1)
        
    finally:
        if conn:
            conn.close()
