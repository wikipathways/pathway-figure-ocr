#!/usr/bin/env python3
# -*- coding: utf-8 -*-

from wand.image import Image
import psycopg2
import psycopg2.extras
from get_pg_conn import get_pg_conn


try:
    conn = get_pg_conn()
    figures_cur = conn.cursor(cursor_factory=psycopg2.extras.DictCursor)
    figures_cur.execute("SELECT * FROM figures;")
    for figure_row in figures_cur.fetchall():
        print('Processing ' + figure_row["filepath"])
        figure_id = figure_row["id"]
        filepath = figure_row["filepath"]
        with Image(filename=filepath) as img:
            resolution = int(round(min(img.resolution)))
            print("resolution: %s figure_id: %s" % (resolution, figure_id))
            figures_cur.execute("UPDATE figures SET resolution = (%s) WHERE id = (%s);", (resolution, figure_id))
            #  UPDATE figures SET resolution = 0 WHERE id = 2;
    conn.commit()

except(psycopg2.DatabaseError) as e:
    print('Error %s' % e)
    sys.exit(1)
    
finally:
    if conn:
        conn.close()
