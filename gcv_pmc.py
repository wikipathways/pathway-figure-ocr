#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import argparse
import json
from pathlib import Path
import psycopg2
import psycopg2.extras
import re

from gcv import gcv
from normalize import normalize


parser = argparse.ArgumentParser(
		description='''OCR PMC figures and save to database.''')

conn = psycopg2.connect("dbname=pfocr")
figures_cur = conn.cursor(cursor_factory=psycopg2.extras.DictCursor)
batches_cur = conn.cursor()
runs_cur = conn.cursor(cursor_factory=psycopg2.extras.DictCursor)
runs_figures_cur = conn.cursor(cursor_factory=psycopg2.extras.DictCursor)
words_cur = conn.cursor()
runs_figures_words_cur = conn.cursor(cursor_factory=psycopg2.extras.DictCursor)

try:
    batches_cur.execute("INSERT INTO batches DEFAULT VALUES RETURNING id;", ())
    batch_id = batches_cur.fetchone()[0]
    runs_cur.execute("INSERT INTO runs (batch_id, ocr_engine, processing) VALUES (%s, %s, %s) ON CONFLICT DO NOTHING RETURNING id;", (batch_id, 'gcv', '["gcv"]'))
    run_id = runs_cur.fetchone()[0]

    figures_cur.execute("SELECT * FROM figures LIMIT 1;")
    figure_rows = figures_cur.fetchall()
    for figure_row in figure_rows:
        print('Processing ' + figure_row["path2img"])
        figure_id = figure_row["id"]
        path2img = figure_row["path2img"]
        gcv_result_raw = gcv(filepath=path2img, type='TEXT_DETECTION')
        if len(gcv_result_raw['responses']) != 1:
            print(gcv_result_raw)
            raise ValueError("""
                gcv_pmc.py expects the JSON result from GCV will always be {"responses": [...]},
                with "responses" having just a single value, but
                the result above indicates that assumption was incorrect.
                """)
        gcv_response = gcv_result_raw['responses'][0]
        gcv_response_str = json.dumps(gcv_response)
        p = Path('gcv_response_' + str(figure_id))
        p.write_text(gcv_response_str)
        runs_figures_cur.execute("INSERT INTO runs_figures (run_id, figure_id, result) VALUES (%s, %s, %s) ON CONFLICT DO NOTHING;", (run_id, figure_id, gcv_response_str))
        for text_annotation in gcv_response['textAnnotations'][1:]:
            normalized_word = normalize(text_annotation['description'])
            if normalized_word:
                # This might not be the best way to insert. TODO: look at the proper way to handle this.
                words_cur.execute("INSERT INTO words (word) VALUES (%s) ON CONFLICT (word) DO UPDATE SET word = EXCLUDED.word RETURNING id;", (normalized_word, ))
                word_id = words_cur.fetchone()[0]
                runs_figures_words_cur.execute("INSERT INTO runs_figures_words (run_id, figure_id, word_id) VALUES (%s, %s, %s) ON CONFLICT DO NOTHING;", (run_id, figure_id, word_id))

    conn.commit()
    print('Processing complete')

except(psycopg2.DatabaseError, e):
    print('Error %s' % e)
    sys.exit(1)
    
    
finally:
    
    if conn:
        conn.close()
