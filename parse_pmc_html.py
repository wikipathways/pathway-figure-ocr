#!/usr/bin/env python3
# -*- coding: utf-8 -*-


from bs4 import BeautifulSoup
import json
import os
import re
from pathlib import Path, PurePath

fig_id_re = re.compile(r".*(?:figure|fig|f)\.?\s?(\d+).*", flags=re.IGNORECASE)
pmcid_re = re.compile(r".*(PMC\d+).*")


def parse_pmc_html(args):
    rawhtml_dir = args["dir"]

    pmc_figure_hashlike_to_figure_id = {}
    try:
        for rawhtml_path in os.listdir(rawhtml_dir):
            if re.match('.*\.html$', rawhtml_path, flags=re.IGNORECASE):
                with open(Path(PurePath(rawhtml_dir, rawhtml_path)), "r") as f:
                    soup = BeautifulSoup(f, 'html.parser')
                    for div in soup.find_all("div", class_="rslt"):
                        p = div.find("p", class_="title")
                        image_link = p.find("a").get("image-link")
                        pmcid = pmcid_re.match(image_link).group(1)
                        text = p.get_text()

                        img = div.find('img', src=True, alt=True)
                        if img:
                            img_src = img.get("src")
                            pmc_figure_hashlike = PurePath(img_src).stem
                            pmc_figure_hashlike_to_figure_id[pmc_figure_hashlike] = {
                                    "pmc_figure_hashlike": pmc_figure_hashlike,
                                    "img_src": img_src}

                            if image_link and fig_id_re.match(image_link):
                                figure_id_from_image_link = int(fig_id_re.search(image_link).group(1))

                            if text and fig_id_re.match(text):
                                figure_id_from_text = int(fig_id_re.search(text).group(1))
                                pmc_figure_hashlike_to_figure_id[pmc_figure_hashlike]["figure_id_from_text"] = figure_id_from_text

                            pmc_figure_hashlike_to_figure_id[pmc_figure_hashlike]["figure_id_from_image_link"] = figure_id_from_image_link
                            pmc_figure_hashlike_to_figure_id[pmc_figure_hashlike]["pmcid"] = pmcid
                            pmc_figure_hashlike_to_figure_id[pmc_figure_hashlike]["text"] = text
                            pmc_figure_hashlike_to_figure_id[pmc_figure_hashlike]["image_link"] = image_link

                            alt = img.get("alt")
                            if alt and fig_id_re.match(alt):
                                figure_id = int(fig_id_re.search(alt).group(1))
                                pmc_figure_hashlike_to_figure_id[pmc_figure_hashlike]["figure_id"] = figure_id
#                        elif pmcid:
#                            if pmcid not in pmc_figure_hashlike_to_figure_id:
#                                pmc_figure_hashlike_to_figure_id[pmcid] = {
#                                        "pmc_figure_hashlike": None,
#                                        "pmcid": pmcid}
#
#                                if image_link and fig_id_re.match(image_link):
#                                    figure_id_from_image_link = int(fig_id_re.search(image_link).group(1))
#                                    pmc_figure_hashlike_to_figure_id[pmcid]["figure_id_from_image_link"] = figure_id_from_image_link
#
#                                if text and fig_id_re.match(text):
#                                    figure_id_from_text = int(fig_id_re.search(text).group(1))
#                                    pmc_figure_hashlike_to_figure_id[pmcid]["figure_id_from_text"] = figure_id_from_text
#                            else:
#                                print(div)
#                                print(pmcid)
#                                raise Exception("Tried adding this pmcid twice for %s" % rawhtml_path)
#                        else:
#                            print(div)
#                            raise Exception("Failed to find matching img for %s" % rawhtml_path)

    except(Exception) as e:
        print('Unexpected Error:', e)
        raise

    #print(pmc_figure_hashlike_to_figure_id)
    print(json.dumps(pmc_figure_hashlike_to_figure_id))
    return pmc_figure_hashlike_to_figure_id

if __name__ == '__main__':
    parse_pmc_html({"dir": "../pmc/20181216/rawhtml/"})
