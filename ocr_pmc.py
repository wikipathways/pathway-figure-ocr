#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import json
from pathlib import Path
import psycopg2
import psycopg2.extras
import re
import hashlib
from dill.source import getsource

def ocr_pmc(
        prepare_image,
        perform_ocr,
        engine,
        start=0,
        end=None,
        *args,
        **kwargs):
    conn = psycopg2.connect("dbname=pfocr")
    figures_cur = conn.cursor(cursor_factory=psycopg2.extras.DictCursor)
    ocr_processors_cur = conn.cursor(cursor_factory=psycopg2.extras.DictCursor)
    ocr_processors__figures_cur = conn.cursor(cursor_factory=psycopg2.extras.DictCursor)

    print('Running ocr_pmc, using ' + engine)
    if start:
        print('start: ' + str(start))
    if end:
        print('end: ' + str(end))

    try:
        prepare_image_str = getsource(prepare_image)
        perform_ocr_str = getsource(perform_ocr)
        ocr_processor_hash = hashlib.sha1((prepare_image_str + perform_ocr_str).encode()).hexdigest()

        ocr_processor_hash_to_id = dict();

        ocr_processors_cur.execute("SELECT id, hash FROM ocr_processors;")
        ocr_processor_rows = ocr_processors_cur.fetchall()
        for ocr_processor_row in ocr_processor_rows:
            ocr_processor_hash_to_id[ocr_processor_row["hash"]] = ocr_processor_row["id"]

        ocr_processor_id = None
        if ocr_processor_hash in ocr_processor_hash_to_id:
            ocr_processor_id = ocr_processor_hash_to_id[ocr_processor_hash]
        else:
            ocr_processors_cur.execute("INSERT INTO ocr_processors (hash, engine, prepare_image, perform_ocr) VALUES (%s, %s, %s, %s) RETURNING id;", (ocr_processor_hash, engine, prepare_image_str, perform_ocr_str))
            ocr_processor_id = ocr_processors_cur.fetchone()[0]
            ocr_processor_hash_to_id[ocr_processor_hash] = ocr_processor_id

        figures_cur.execute("SELECT * FROM figures;")
        figure_rows = figures_cur.fetchall()
        for figure_row in figure_rows[start:end]:
            print('Processing ' + figure_row["filepath"])
            figure_id = figure_row["id"]
            raw_filepath = figure_row["filepath"]
            prepared_filepath = prepare_image(raw_filepath)
            ocr_result = perform_ocr(prepared_filepath)
            if ocr_result is None:
                print(ocr_result)
                raise ValueError("""
                    ocr_pmc.py expects the result from the ocr engine to not be empty,
                    but the result above indicates that assumption was incorrect.
                    """)
            ocr_processors__figures_cur.execute("INSERT INTO ocr_processors__figures (ocr_processor_id, figure_id, result) VALUES (%s, %s, %s);", (ocr_processor_id, figure_id, json.dumps(ocr_result)))

        conn.commit()
        print('ocr_pmc successfully completed')

    except(psycopg2.DatabaseError, e):
        print('Error %s' % e)
        sys.exit(1)
        
    finally:
        if conn:
            conn.close()
