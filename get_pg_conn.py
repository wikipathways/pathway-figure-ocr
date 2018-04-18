import psycopg2

def get_pg_conn():
    return psycopg2.connect("dbname=pfocr")
