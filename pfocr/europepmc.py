#!/usr/bin/env python3
# -*- coding: utf-8 -*-

# Submission instructions:
# https://europepmc.org/AnnotationsSubmission

# We are currently using the "sentence-based annotations" format

# Here's a useful jq query to get all the annotation exact values:
# python europepmc.py | jq -s '.[] | .anns[] | .exact'
# And one to get figure_filepath and position (but you must first uncomment figure_filepath in the code):
# python europepmc.py | jq -s '.[] | .anns[] | {exact, figure_filepath}'

# TODO: run the output through this
# https://github.com/EuropePMC/EuropePMC-Annotation-Validator

import json
import csv
import os
import psycopg2
import psycopg2.extras
import re
import sys
from pathlib import Path, PurePath

from get_pg_conn import get_pg_conn

# If we see more figures in a paper than this,
# we should double-check whether we have a
# valid figure number.
MAX_EXPECTED_FIGURE_COUNT = 20
CURRENT_SCRIPT_PATH = os.path.dirname(sys.argv[0])

fig_id_re = re.compile(r".*(?:figure|fig|f)\.?\s?(\d+).*", flags=re.IGNORECASE)


def europepmc(args):
    db = args.db

    conn = get_pg_conn(db)
    annotations_cur = conn.cursor(cursor_factory=psycopg2.extras.DictCursor)

    try:
        # TODO: should we try using data from the HTML in here?
        # If so, where should we store it? How do we build and distribute it?
        #parsedhtml = json.loads(open(Path(PurePath(CURRENT_SCRIPT_PATH, "parsedhtml.json")), "r").read())

        annotations_query = '''
        SELECT pmcid, figure_filepath, word, symbol, source, hgnc_symbol, xref as entrez
        FROM figures__xrefs
        ORDER BY pmcid, figure_filepath, word;
        '''
        annotations_cur.execute(annotations_query)

        annotations_by_pmcid = {}
        for row in annotations_cur:
            pmcid = row["pmcid"]
            figure_filepath = row["figure_filepath"]

            if pmcid not in annotations_by_pmcid:
                annotations_by_pmcid[pmcid] = {
                    "src": "PMC",
                    "id": pmcid,
                    "provider": "wikipathways",
                    "anns": []
                    }

#            # NOTE: the code below still can't find a figure id for
#            # a few results, such as
#            # /home/pfocr/pmc/20181216/images/PMC5768180__fimmu-08-01938-g006b.jpg
#            stem = (PurePath(figure_filepath).stem)
#            pmc_figure_hashlike = stem.split('__')[1]
#            figure_id_candidates = []
#            if pmc_figure_hashlike in parsedhtml:
#                parsedhtml_data = parsedhtml[pmc_figure_hashlike]
#                figure_id_candidates.append(parsedhtml_data.get("figure_id"))
#                figure_id_candidates.append(parsedhtml_data.get("figure_id_from_image_link"))
#                figure_id_candidates.append(parsedhtml_data.get("figure_id_from_text"))
#            else:
#                parsedhtml_data_candidates = []
#                for v in parsedhtml.values():
#                    if v["pmcid"] == pmcid:
#                        parsedhtml_data_candidates.append(v)
#                parsedhtml_data = None
#                if len(parsedhtml_data_candidates) == 1:
#                    parsedhtml_data = parsedhtml_data_candidates[0]
#                    figure_id_candidates.append(parsedhtml_data.get("figure_id"))
#                    figure_id_candidates.append(parsedhtml_data.get("figure_id_from_image_link"))
#                    figure_id_candidates.append(parsedhtml_data.get("figure_id_from_text"))
#
#            if fig_id_re.match(stem):
#                figure_id_candidates.append(int(fig_id_re.search(stem).group(1)))
#
#            figure_id = next((item for item in figure_id_candidates if item is not None), None)
#            #figure_id = next(item for item in figure_id_candidates if item is not None)
#            
#            print(figure_id_candidates)
#            if not figure_id:
#                print(figure_filepath)
#                if pmc_figure_hashlike in parsedhtml:
#                    parsedhtml_data = parsedhtml[pmc_figure_hashlike]
#                    print(parsedhtml_data)
#                raise Exception('Failed to get figure_id for the data above')

            word = row["word"]
            symbol = row["symbol"]
            source = row["source"]
            hgnc_symbol = row["hgnc_symbol"]
            entrez = row["entrez"]
            # NOTE: We could extract a crop of the figure corresponding to
            # bounding box of the matched text and base64-encode it.
            #"figure": os.path.basename(figure_filepath),

            # TODO: don't add the same value again if it has the same entrez
            # for a given pmcid
            annotations_by_pmcid[pmcid]["anns"].append(
                    {
                        # figure_filepath is just for our internal dev use.
                        #"figure_filepath": figure_filepath,
                        "exact": symbol,
                        "section": "Figure",
                        "tags": [
                            {
                                "name": hgnc_symbol,
                                "uri": "http://identifiers.org/ncbigene/" + entrez
                                }
                            ]
                        })

        for row in annotations_by_pmcid.values():
            # TODO should we allow the user to specify an output file location?
            print(json.dumps(row))

    # TODO: check whether we're getting more than 10k rows. From the docs:
    # Every file must have less than 10000 rows, where each row represents an
    # individual article with all associated annotations. If your dataset
    # contains more than 10000 articles, and thus you have more than 10000 rows
    # to upload, you can generate multiple files and then submit either a zip or
    # a gzipped tar file containing all the data.
    # unix command: tar -czvf submission_file.tar.gz ./*

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
    europepmc(None)
