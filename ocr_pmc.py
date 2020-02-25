#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import image_preprocessors
import ocr_engines
import json
from pathlib import Path
import psycopg2
import psycopg2.extras
import re
import hashlib
import sys
from dill.source import getsource

from get_pg_conn import get_pg_conn

def get_engines():
    return ocr_engines.__all__

def ocr_pmc(
        engine,
        preprocessor="noop",
        limit=None,
        *args,
        **kwargs):
    conn = get_pg_conn()
    figures_cur = conn.cursor(cursor_factory=psycopg2.extras.DictCursor)
    ocr_processors_cur = conn.cursor(cursor_factory=psycopg2.extras.DictCursor)
    ocr_processors__figures_cur = conn.cursor(cursor_factory=psycopg2.extras.DictCursor)

    perform_ocr = getattr(getattr(ocr_engines, engine), engine)
    if not perform_ocr:
        raise Exception('OCR engine "%s" not recognized.' % engine)

    prepare_image = getattr(getattr(image_preprocessors, preprocessor), preprocessor)
    if not prepare_image:
        raise Exception('image preprocessor "%s" not recognized' % engine)


    print('Running ocr_pmc, using ' + engine)

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
            ocr_processors_cur.execute('''
                INSERT INTO ocr_processors (hash, engine, prepare_image, perform_ocr)
                VALUES (%s, %s, %s, %s) RETURNING id;
                ''', (ocr_processor_hash, engine, prepare_image_str, perform_ocr_str))
            ocr_processor_id = ocr_processors_cur.fetchone()[0]
            ocr_processor_hash_to_id[ocr_processor_hash] = ocr_processor_id

        # Find figures that haven't been handled by this processor already
        figures_cur.execute('''
            SELECT figures.id, filepath FROM figures
            LEFT OUTER JOIN ocr_processors__figures ON figures.id = ocr_processors__figures.figure_id
            WHERE ((ocr_processors__figures.ocr_processor_id IS NULL OR ocr_processors__figures.ocr_processor_id <> %s)
                AND figures.id NOT IN (SELECT figure_id FROM ocr_processors__figures WHERE ocr_processor_id = %s));
            ''', (ocr_processor_id, ocr_processor_id))
        figure_rows = figures_cur.fetchall()

        print('limit: {}'.format(limit))

        print('number of figures yet to be processed by ocr_processor {ocr_processor_id}: {remaining_figure_count}'.format(ocr_processor_id=ocr_processor_id, remaining_figure_count=len(figure_rows)))

        for figure_row in figure_rows[0:limit]:
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
            # TODO: should we commit here to avoid losing OCR work we've done in case there's an error or something?

        conn.commit()
        print('ocr_pmc successfully completed')

    except(psycopg2.DatabaseError) as e:
        print('Error %s' % e)
        sys.exit(1)
        
    finally:
        if conn:
            conn.close()
