import psycopg2

def get_conn():
    return psycopg2.connect("dbname=pfocr2")
