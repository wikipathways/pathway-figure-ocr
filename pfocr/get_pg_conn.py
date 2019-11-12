import psycopg2
import os
from pathlib import Path, PurePath
import sys


# Set current database like this: (export PFOCR_DB='pfocr20190128b'; ./pfocr/pfocr.py europepmc)


def get_pg_conn(db):
    if not db:
        if 'PFOCR_DB' in os.environ and os.environ['PFOCR_DB']:
            db = os.environ['PFOCR_DB']
        else:
            raise Exception('Error: you need to either specify parameter "db" or set env variable "PFOCR_DB".')

    return psycopg2.connect("dbname=%s" % db)
