#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import argparse
import json
from pathlib import Path
import psycopg2
import re

from postprocess import postprocess
from ocr_pmc import ocr_pmc
from gcv import gcv


def gcv_figures(args):
    def prepare_image(filepath):
        return filepath

    def do_gcv(prepared_filepath):
        gcv_result_raw = gcv(filepath=prepared_filepath, type='TEXT_DETECTION')
        if len(gcv_result_raw['responses']) != 1:
            print(gcv_result_raw)
            raise ValueError("""
                gcv_pmc.py expects the JSON result from GCV will always be {"responses": [...]},
                with "responses" having just a single value, but
                the result above indicates that assumption was incorrect.
                """)
        return gcv_result_raw['responses'][0]
    start = args.start
    end = args.end
    ocr_pmc(prepare_image, do_gcv, "gcv", start, end)

def load_figures(args):
    # TODO don't hard code things like the figure path
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

# Create parser and subparsers
parser = argparse.ArgumentParser(
                prog='pfocr',
		description='''Process figures to extract pathway data.''')
subparsers = parser.add_subparsers(title='subcommands',
        description='valid subcommands',
        help='additional help')

# create the parser for the "gcv_figures" command
parser_gcv_figures = subparsers.add_parser('gcv_figures',
        help='Run GCV on PMC figures and save results to database.')
parser_gcv_figures.add_argument('--start',
		type=int,
		help='start of figures to process')
parser_gcv_figures.add_argument('--end',
		type=int,
		help='end of figures to process')
parser_gcv_figures.set_defaults(func=gcv_figures)

# create the parser for the "load_figures" command
parser_load_figures = subparsers.add_parser('load_figures')
parser_load_figures.set_defaults(func=load_figures)

# create the parser for the "postprocess" command
parser_postprocess = subparsers.add_parser('postprocess',
        help='Extract data from OCR result and put into DB tables.')
parser_postprocess.set_defaults(func=postprocess)

args = parser.parse_args()
args.func(args)
