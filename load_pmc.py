#!/usr/bin/env python3
# -*- coding: utf-8 -*-

from pathlib import Path
import psycopg2
import re

pmcid_re = re.compile('^(PMC\d+)__(.+)')

conn = psycopg2.connect("dbname=pfocr")
papers_cur = conn.cursor()
figures_cur = conn.cursor()

p = Path(Path(__file__).parent)
figure_paths = list(p.glob('../pmc/20150501/images_pruned/*.jpg'))

pmcid_to_paper_id = dict();

try:
    for figure_path in figure_paths:
        filepath = str(figure_path.resolve())
        name_components = pmcid_re.match(figure_path.stem)
        if name_components:
            pmcid = name_components[1]
            figure_number = name_components[2]
            print("Processing pmcid: " + pmcid + ", figure_number: " + figure_number)
            paper_id = None
            if pmcid in pmcid_to_paper_id:
                paper_id = pmcid_to_paper_id[pmcid]
            else:
                papers_cur.execute("INSERT INTO papers (pmcid) VALUES (%s) RETURNING id;", (pmcid, ))
                paper_id = papers_cur.fetchone()[0]
                pmcid_to_paper_id[pmcid] = paper_id

            figures_cur.execute("INSERT INTO figures (filepath, figure_number, paper_id) VALUES (%s, %s, %s);", (filepath, figure_number, paper_id))

    conn.commit()

    print('load_pmc sucessfully completed.')

except(psycopg2.DatabaseError, e):
    print('Error %s' % e)
    sys.exit(1)
    
finally:
    if papers_cur:
        papers_cur.close()
    if figures_cur:
        figures_cur.close()
    if conn:
        conn.close()
