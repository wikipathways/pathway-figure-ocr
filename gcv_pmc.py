#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import argparse
from gcv import gcv
import json
from pathlib import Path
import psycopg2
import psycopg2.extras
import re

parser = argparse.ArgumentParser(
		description='''OCR PMC figures and save to database.''')

conn = psycopg2.connect("dbname=pfocr")
figures_cur = conn.cursor(cursor_factory=psycopg2.extras.DictCursor)
batches_cur = conn.cursor(cursor_factory=psycopg2.extras.DictCursor)
runs_cur = conn.cursor(cursor_factory=psycopg2.extras.DictCursor)
runs_figures_cur = conn.cursor(cursor_factory=psycopg2.extras.DictCursor)

try:
    batches_cur.execute("INSERT INTO batches (paper_count) VALUES (%s) ON CONFLICT DO NOTHING RETURNING id;", (0, ))
    batch_id = batches_cur.fetchone()[0]
    runs_cur.execute("INSERT INTO runs (batch_id, ocr_engine, processing) VALUES (%s, %s, %s) ON CONFLICT DO NOTHING RETURNING id;", (batch_id, 'gcv', '["gcv"]'))
    run_id = runs_cur.fetchone()[0]

    figures_cur.execute("SELECT * FROM figures LIMIT 20;")
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
        gcv_result = json.dumps(gcv_result_raw['responses'][0])
        runs_figures_cur.execute("INSERT INTO runs_figures (run_id, figure_id, result) VALUES (%s, %s, %s) ON CONFLICT DO NOTHING;", (run_id, figure_id, gcv_result))

    conn.commit()
    print('Processing complete')

except(psycopg2.DatabaseError, e):
    print('Error %s' % e)
    sys.exit(1)
    
    
finally:
    
    if conn:
        conn.close()
