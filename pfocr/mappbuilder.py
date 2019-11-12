#!/usr/bin/env python3
# -*- coding: utf-8 -*-

# Create four column MAPPBuilder files for the matches in the database
# Example: (export PFOCR_DB='pfocr20190128b'; ./pfocr/pfocr.py mappbuilder mappbuilder/inputs/ mappbuilder/outputs)
#
# a bash command to compress these: tar -zcf mappbuilder-results.tar.gz mappbuilder/outputs

import csv
from os import path, makedirs
import shutil
import psycopg2
import psycopg2.extras
import sys
from pathlib import Path, PurePath

from get_pg_conn import get_pg_conn


BRIDGEDB_SYSTEM_CODE_ENTREZ = 'L'


def write_mappbuilder_file(OUTPUT_DIR, sub_dir, figure_file_stem, matches):
    tsv_name = str(PurePath(OUTPUT_DIR, sub_dir, figure_file_stem + '.tsv'))
    with open(tsv_name, 'w', newline='') as tsvfile:
        for match in matches:
            matchwriter = csv.writer(tsvfile, dialect='excel-tab', quoting=csv.QUOTE_MINIMAL)
            matchwriter.writerow(match)


def mappbuilder(db, input_dir, output_dir):
    INPUT_DIR = PurePath(input_dir)
    OUTPUT_DIR = PurePath(output_dir)

    conn = get_pg_conn(db)
    annotations_cur = conn.cursor(cursor_factory=psycopg2.extras.DictCursor)

    try:
        if not path.exists(OUTPUT_DIR):
            makedirs(OUTPUT_DIR)
        else:
            # TODO: error or just delete?
            raise Exception("Error: output directory %s already exists" % OUTPUT_DIR)
            #shutil.rmtree(OUTPUT_DIR)
            #makedirs(OUTPUT_DIR)

        expected_inputs = ['top100novel', 'top100disease', 'top100novel_disease']
        for expected_input in (expected_inputs + ['all']):
            dir_name = PurePath(OUTPUT_DIR, expected_input)
            if not path.exists(dir_name):
                makedirs(dir_name)

        figure_basenames_by_category = dict()
        for expected_input in expected_inputs:
            figure_basenames_by_category[expected_input] = set(open(Path(PurePath(
                INPUT_DIR, expected_input + ".txt")), "r").read().split('\n'))

        annotations_query = '''
        SELECT DISTINCT pmcid, figure_filepath, word, hgnc_symbol, xref as entrez
        FROM figures__xrefs
        ORDER BY pmcid, figure_filepath, hgnc_symbol;
        '''
        annotations_cur.execute(annotations_query)

        annotations_by_basename = {}
        for row in annotations_cur:
            pmcid = row["pmcid"]
            figure_filepath = row["figure_filepath"]
            figure_file_basename = path.basename(figure_filepath)

            if figure_file_basename not in annotations_by_basename:
                annotations_by_basename[figure_file_basename] = []

            word = row["word"]
            hgnc_symbol = row["hgnc_symbol"]
            entrez = row["entrez"]

            # NOTE: this is currently using the four column format
            #       requested by Tina:
            # label, id, system code, original label 
            # To get the normal three column format, remove "word" below.
            annotations_by_basename[figure_file_basename].append(
                    [hgnc_symbol, entrez, BRIDGEDB_SYSTEM_CODE_ENTREZ, word])

        for figure_file_basename,matches in annotations_by_basename.items():
            figure_file_stem = PurePath(figure_file_basename).stem

            write_mappbuilder_file(OUTPUT_DIR, 'all', figure_file_stem, matches)

            for category,figure_basenames in figure_basenames_by_category.items():
                if figure_file_basename in figure_basenames:
                    write_mappbuilder_file(OUTPUT_DIR, category, figure_file_stem, matches)

    except(psycopg2.DatabaseError) as e:
        print('Database Error %s' % psycopg2.DatabaseError)
        print('Database Error (same one): %s' % e)
        print('Database Error (same one):', e)
        raise

    except(Exception) as e:
        print('Unexpected Error:', e)
        raise

    finally:
        if conn:
            conn.close()

def mappbuilder_cli(args):
    mappbuilder(db=args.db, input_dir=args.input_dir, output_dir=args.output_dir)
