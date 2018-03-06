#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import psycopg2
import psycopg2.extras
import re
from normalize import normalize

def postprocess(args):
    # TODO do we want to do anything with args?
    conn = psycopg2.connect("dbname=pfocr")
    ocr_processors__figures_cur = conn.cursor(cursor_factory=psycopg2.extras.DictCursor)

    words_cur = conn.cursor()
    ocr_processors__figures__words_cur = conn.cursor(cursor_factory=psycopg2.extras.DictCursor)

    try:
        ocr_processors__figures__words_cur.execute("DELETE FROM ocr_processors__figures__words;")
        words_cur.execute("DELETE FROM words;")

        query = '''
        /* This query might seem as if it could be simpler, but we have to account
           for the case of a result with just one textAnnotation. The extra
           complexity of this query is to ensure we don't exclude
           the description for such a lone textAnnotation. */
        WITH descriptions AS (
                SELECT ocr_processor_id, figure_id, jsonb_extract_path(jsonb_array_elements(jsonb_extract_path(result, 'textAnnotations')), 'description') AS description
                FROM ocr_processors__figures
        ),
        first_descriptions AS (
                SELECT jsonb_extract_path(result, 'textAnnotations', '0', 'description') AS first_description
                FROM ocr_processors__figures
                WHERE jsonb_array_length(jsonb_extract_path(result, 'textAnnotations')) > 1
        )
        SELECT DISTINCT ocr_processor_id, figure_id, description
        FROM descriptions
        LEFT JOIN first_descriptions
        ON descriptions.description = first_descriptions.first_description
        WHERE first_descriptions.first_description IS NULL;
        '''
        ocr_processors__figures_cur.execute(query)

        ocr_processor__figure__word_rows = ocr_processors__figures_cur.fetchall()
        word_ids_by_normalized_word = {}

        for row in ocr_processor__figure__word_rows:
            ocr_processor_id = row[0]
            figure_id = row[1]
            word = row[2]
            normalized_word = normalize(word)
            if normalized_word: 
                word_id = ""
                if normalized_word not in word_ids_by_normalized_word: 
                    # This might not be the best way to insert. TODO: look at the proper way to handle this.
                    words_cur.execute("INSERT INTO words (word) VALUES (%s) ON CONFLICT (word) DO UPDATE SET word = EXCLUDED.word RETURNING id;", (normalized_word, ))
                    word_id = words_cur.fetchone()[0]
                    word_ids_by_normalized_word[normalized_word] = word_id
                else:
                    word_id = word_ids_by_normalized_word[normalized_word]

                ocr_processors__figures__words_cur.execute("INSERT INTO ocr_processors__figures__words (ocr_processor_id, figure_id, word_id) VALUES (%s, %s, %s) ON CONFLICT DO NOTHING;", (ocr_processor_id, figure_id, word_id))

        conn.commit()
        print('postprocess successfully completed')

    except(psycopg2.DatabaseError, e):
        print('Error %s' % psycopg2.DatabaseError)
        print('Error %s' % e)
        sys.exit(1)
        
    finally:
        if conn:
            conn.close()
