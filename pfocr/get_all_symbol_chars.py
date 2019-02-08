#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import json
import psycopg2
import psycopg2.extras
import re
import sys
from get_pg_conn import get_pg_conn


alphanumeric_re = re.compile('\w')


def get_all_symbol_chars(args):
    db = args.db

    conn = get_pg_conn(db)
    symbols_cur = conn.cursor(cursor_factory=psycopg2.extras.DictCursor)

    try:
        symbols_query = '''
        SELECT id, symbol
        FROM symbols;
        '''
        symbols_cur.execute(symbols_query)

        symbol_chars = set()

        # original symbol incl/
        symbol_ids_by_symbol = {}
        for s in symbols_cur:
            symbol_id = s["id"]
            symbol = s["symbol"]
            for c in list(symbol):
                symbol_chars.add(c)
                if ord(c) > 128:
                    print("symbol ", symbol, " contains character ", c, ", which is outside ascii set")

        with open("./symbol_chars.json", "w") as symbol_chars_file:
            symbol_chars_list = list(symbol_chars)
            symbol_chars_list.sort()
            symbol_chars_file.write(json.dumps(symbol_chars_list))

        #conn.commit()

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
    get_all_symbol_chars(1)
