import psycopg2
import os
from pathlib import Path, PurePath
import sys


# Set current database like this: (export PFOCR_DB='pfocr20190128b'; ./pfocr/pfocr.py europepmc)


def get_pg_conn(args):
    db = args.db
    if not db:
        db = os.environ['PFOCR_DB']
        if not db:
            raise Exception('Error: neither db arg nor PFOCR_DB env variable set.')
    return psycopg2.connect("dbname=%s" % db)
