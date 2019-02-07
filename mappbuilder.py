#!/usr/bin/env python3
# -*- coding: utf-8 -*-

# Create four column MAPPBuilder files for the matches in the database
# bash command to compress these: tar -zcf mappbuilder.tar.gz mappbuilder

import csv
from os import path, makedirs
import shutil
import psycopg2
import psycopg2.extras
import sys
from pathlib import Path, PurePath

from get_pg_conn import get_pg_conn


CURRENT_SCRIPT_DIR = path.dirname(path.abspath(__file__))
OUTPUT_DIR = PurePath(CURRENT_SCRIPT_DIR, "mappbuilder")
BRIDGEDB_SYSTEM_CODE_ENTREZ = 'L'


def write_mappbuilder_file(sub_dir, figure_file_stem, matches):
    tsv_name = str(PurePath(OUTPUT_DIR, sub_dir, figure_file_stem + '.tsv'))
    with open(tsv_name, 'w', newline='') as tsvfile:
        for match in matches:
            matchwriter = csv.writer(tsvfile, dialect='excel-tab', quoting=csv.QUOTE_MINIMAL)
            matchwriter.writerow(match)


def mappbuilder(args):
    conn = get_pg_conn()
    annotations_cur = conn.cursor(cursor_factory=psycopg2.extras.DictCursor)

    try:
        top100novel_figure_basenames = set(open(Path(PurePath(
            CURRENT_SCRIPT_DIR, "top100novel.txt")), "r").read().split('\n'))
        top100disease_figure_basenames = set(open(Path(PurePath(
            CURRENT_SCRIPT_DIR, "top100disease.txt")), "r").read().split('\n'))
        top100novel_disease_figure_basenames = set(open(Path(PurePath(
            CURRENT_SCRIPT_DIR, "top100novel_disease.txt")), "r").read().split('\n'))

        shutil.rmtree(OUTPUT_DIR)
        makedirs(PurePath(OUTPUT_DIR, 'top100novel'))
        makedirs(PurePath(OUTPUT_DIR, 'top100disease'))
        makedirs(PurePath(OUTPUT_DIR, 'top100novel_disease'))
        makedirs(PurePath(OUTPUT_DIR, 'all'))

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

            write_mappbuilder_file('all', figure_file_stem, matches)

            if figure_file_basename in top100novel_figure_basenames:
                write_mappbuilder_file('top100novel', figure_file_stem, matches)
            if figure_file_basename in top100disease_figure_basenames:
                write_mappbuilder_file('top100disease', figure_file_stem, matches)
            if figure_file_basename in top100novel_disease_figure_basenames:
                write_mappbuilder_file('top100novel_disease', figure_file_stem, matches)

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

if __name__ == '__main__':
    mappbuilder(None)
