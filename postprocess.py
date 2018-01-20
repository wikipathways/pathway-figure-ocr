# TODO this file won't work as-is. I just moved the postprocessing code out of gcv_pmc.py
import psycopg2
import psycopg2.extras
import re

from normalize import normalize


def postprocess(run_id, figure_id):
    conn = psycopg2.connect("dbname=pfocr")
    words_cur = conn.cursor()
    runs_figures_words_cur = conn.cursor(cursor_factory=psycopg2.extras.DictCursor)
    for text_annotation in gcv_response['textAnnotations'][1:]:
        normalized_word = normalize(text_annotation['description'])
        if normalized_word:
            # This might not be the best way to insert. TODO: look at the proper way to handle this.
            words_cur.execute("INSERT INTO words (word) VALUES (%s) ON CONFLICT (word) DO UPDATE SET word = EXCLUDED.word RETURNING id;", (normalized_word, ))
            word_id = words_cur.fetchone()[0]
            runs_figures_words_cur.execute("INSERT INTO runs_figures_words (run_id, figure_id, word_id) VALUES (%s, %s, %s) ON CONFLICT DO NOTHING;", (run_id, figure_id, word_id))
