#!/usr/bin/env python3
# -*- coding: utf-8 -*-

# Submission instructions:
# https://europepmc.org/AnnotationsSubmission

# We are currently using the "sentence-based annotations" format

# Useful Commands:
#
# Save to file:
# ./pfocr.py europepmc pfocr2018121717 > ../europepmc_wikipathways_20190219.json 
#
# Use jq query to get all the annotation exact values:
# python europepmc.py | jq -s '.[] | .anns[] | .exact'

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
        SELECT DISTINCT pmcid, symbol, hgnc_symbol, xref as entrez
        FROM figures__xrefs
        ORDER BY pmcid, symbol;
        '''
        annotations_cur.execute(annotations_query)

        annotations_by_pmcid = {}
        for row in annotations_cur:
            pmcid = row["pmcid"]

            if pmcid not in annotations_by_pmcid:
                annotations_by_pmcid[pmcid] = {
                    "src": "PMC",
                    "id": pmcid,
                    "provider": "wikipathways",
                    "anns": []
                    }

            symbol = row["symbol"]
            hgnc_symbol = row["hgnc_symbol"]
            entrez = row["entrez"]

            # TODO: don't add the same value again if it has the same entrez
            # for a given pmcid
            annotations_by_pmcid[pmcid]["anns"].append(
                    {
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
