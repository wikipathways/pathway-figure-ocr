#!/usr/bin/env python3
# -*- coding: utf-8 -*-


import sys
from bs4 import BeautifulSoup
import json
import os
import re
from pathlib import Path, PurePath
import psycopg2
import psycopg2.extras

from get_pg_conn import get_pg_conn

fig_id_re = re.compile(r".*(?:figure|fig|f)\.?\s?(S?\d+).*", flags=re.IGNORECASE)
pmcid_re = re.compile(r".*(PMC\d+).*")


def parse_pmc_html(args):
    rawhtml_dir = args["dir"]

    conn = get_pg_conn()
    figures_cur = conn.cursor(cursor_factory=psycopg2.extras.DictCursor)

    pmc_figure_hashlike_to_figure_id = {}
    try:
        for rawhtml_path in os.listdir(rawhtml_dir)[:1]:
            if re.match('.*\.html$', rawhtml_path, flags=re.IGNORECASE):
                with open(Path(PurePath(rawhtml_dir, rawhtml_path)), "r") as f:
                    soup = BeautifulSoup(f, 'html.parser')
                    for div in soup.find_all("div", class_="rslt"):
                        #print('***********************************')
                        #print(div.prettify())

                        #image_link = div.find("a", class_="imagepopup").get("image-link")
                        image_link = div.find("a").get("image-link")
                        if not image_link:
                            raise Exception('Error: missing image_link in div above!')
                        pmcid = pmcid_re.match(image_link).group(1)

                        title = div.find("p", class_="title").get_text()
                        details = div.find('p', class_="details").get_text()

                        img = div.find('img', src=True, alt=True)
                        if img:
                            img_src = img.get("src")
                            pmc_figure_hashlike = PurePath(img_src).stem
                            pmc_figure_hashlike_to_figure_id[pmc_figure_hashlike] = {
                                    "pmc_figure_hashlike": pmc_figure_hashlike,
                                    "img_src": img_src}

                            if image_link and fig_id_re.match(image_link):
                                figure_id_from_image_link = fig_id_re.search(image_link).group(1)

                            if title and fig_id_re.match(title):
                                figure_id_from_title = fig_id_re.search(title).group(1)
                                pmc_figure_hashlike_to_figure_id[pmc_figure_hashlike]["figure_id_from_title"] = figure_id_from_title

                            pmc_figure_hashlike_to_figure_id[pmc_figure_hashlike]["figure_id_from_image_link"] = figure_id_from_image_link
                            pmc_figure_hashlike_to_figure_id[pmc_figure_hashlike]["pmcid"] = pmcid
                            pmc_figure_hashlike_to_figure_id[pmc_figure_hashlike]["title"] = title
                            pmc_figure_hashlike_to_figure_id[pmc_figure_hashlike]["details"] = details
                            pmc_figure_hashlike_to_figure_id[pmc_figure_hashlike]["image_link"] = image_link

                            alt = img.get("alt")
                            if alt and fig_id_re.match(alt):
                                figure_id = fig_id_re.search(alt).group(1)
                                pmc_figure_hashlike_to_figure_id[pmc_figure_hashlike]["figure_id"] = figure_id

#                        elif pmcid:
#                            if pmcid not in pmc_figure_hashlike_to_figure_id:
#                                pmc_figure_hashlike_to_figure_id[pmcid] = {
#                                        "pmc_figure_hashlike": None,
#                                        "pmcid": pmcid}
#
#                                if image_link and fig_id_re.match(image_link):
#                                    figure_id_from_image_link = fig_id_re.search(image_link).group(1)
#                                    pmc_figure_hashlike_to_figure_id[pmcid]["figure_id_from_image_link"] = figure_id_from_image_link
#
#                                if title and fig_id_re.match(title):
#                                    figure_id_from_title = fig_id_re.search(title).group(1)
#                                    pmc_figure_hashlike_to_figure_id[pmcid]["figure_id_from_title"] = figure_id_from_title
#                            else:
#                                print(div)
#                                print(pmcid)
#                                raise Exception("Tried adding this pmcid twice for %s" % rawhtml_path)
#                        else:
#                            print(div)
#                            raise Exception("Failed to find matching img for %s" % rawhtml_path)

            figures_cur.execute(
                "UPDATE figures SET figure_number = %s, caption = %s WHERE filepath = %s;",
                (figure_number, details, pmc, filepath)
            )


    except(psycopg2.DatabaseError) as e:
        print('Database Error %s' % e, '\n', 'clear %s: FAIL' % target)
        conn.rollback()
        raise

    except(Exception) as e:
        print('Unexpected Error:', sys.exc_info()[0], '\n', e)
        conn.rollback()
        raise

    finally:
        if conn:
            conn.close()

    #print(pmc_figure_hashlike_to_figure_id)
    print(json.dumps(pmc_figure_hashlike_to_figure_id))
    return pmc_figure_hashlike_to_figure_id

if __name__ == '__main__':
    parse_pmc_html({"dir": "../pmc/20181216/rawhtml/"})
