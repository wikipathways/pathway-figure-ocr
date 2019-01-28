import psycopg2
import os
from pathlib import Path, PurePath
import sys


def get_pg_conn():
    CURRENT_SCRIPT_PATH = os.path.dirname(sys.argv[0])
    CURRENT_DB = open(Path(PurePath(CURRENT_SCRIPT_PATH, "CURRENT_DB")), "r").read().splitlines()[0]
    return psycopg2.connect("dbname=%s" % CURRENT_DB)
