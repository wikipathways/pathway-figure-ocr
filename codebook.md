# Codebook for Pathway Figure OCR project
The sections below detail the steps taken to generate files and run scripts for this project.

## PubMed Central Image Extraction

This url returns >40k figures from PMC articles matching "signaling pathways". Approximately 80% of these are actually pathway figures. These make a reasonably efficient source of sample figures to test methods. *Consider other search terms and other sources when scaling up.*

```
http://www.ncbi.nlm.nih.gov/pmc/?term=signaling+pathway&report=imagesdocsum
```

### Scrape HTML
For sample sets you can simply save dozens of pages of results and quickly get 1000s of pathway figures. *Consider automating this step when scaling up.*

```
Set Display Settings: to max (100)
Save raw html to designated folder, e.g., pmc/signaling_pathway/#.#_rawhtml
```

Next, configure and run this php script to generated annotated sets of image and html files.

```
php pmc_image_parse.php
```

* depends on simple_html_dom.php
* outputs images as "PMC######__<filename>.<ext>
* outputs caption as "PMC######__<filename>.<ext>.html

### Prune Images
Another manual step here to increase accuracy of downstream counts. Make a copy of the figures dir, incrementing the version. View the extracted images in Finder, for example, and delete pairs of files associated with figures that are not actually pathways. In this first sample run, ~20% of images were pruned away. The most common non-pathway figures wer of gel electrophoresis runs. *Consider automated ways to either exclude gel figures or select only pathway images to scale this step up.*

### Load into Database
Load filenames (or paths) and extracted content into database

* papers (id, pmcid, title, url)
* figures (id, paperid, path2img, fignumber, caption)

## Optical Character Recognition

### Read in Files from Database
* figures (path2img)

### Image Preprocessing
#### Imagemagick
Exploration of settings to improve OCR by pre-processing of image:

```
convert test1.jpg -colorspace gray test1_gr.jpg
convert test1_gr.jpg -threshold 50% test1_gr_th.jpg 
convert test1_gr_th.jpg -define connected-components:verbose=true -define connected-components:area-threshold=400 -connected-components 4 -auto-level -depth 8 test1_gr_th_cc.jpg
```

### Run Google Cloud Vision
* Set parameters
  * 'LanguageCode':'en' - to restrict to English language characters
* Produce JSON files

### Load filnames (paths) into database
* figures (gcv_json)

## Process Results
### Create/update word tables for all extracted text
* Apply normalization
* word (id, word, n_word)
* figure_word (figure_id, word_id)

### Create/update xref tables for all lexicon "hits"
* xref (id, xref)
* figure_xref (figure_id, xref_id)

### Collect run stats
* run (timestamp, parameters, paper_count, figure_count,  total_word_gross, total_word_unique, total_xrefs_gross, total_xrefs_unique)

## Generating Files and Initial Tables
#### hgnc_list_all_FINAL.txt
1. Downloaded Total Approved Symbols as txt from http://www.genenames.org/cgi-bin/statistics
2. Imported txt into Excel, explicitly choosing "text" for symbol and alias columns during import wizard (to avoid date conversion of SEPT1, etc)
3. Extracted 'symbol', 'alias symbol', and 'prev symbol' into single column with single entries
4. Set all entries to uppercase
5. Added generic symbols for gene families, e.g., "WNT" in addition to all the WNT## entries
6. Also added copies of symbols without hyphens, e.g., "ERVK1" in addition to original "ERVK-1"
7. Note: these two additions above help cover common mistakes/practices among figure makers
8. Saved list as txt file for ID lookup and eng.user-words: hgnc_list_all_FINAL.txt
9. Open in TextWrangler to switch linefeed to "Unix(LF)" to work with php scripts

**Note: a mapping table can be used to map any hits from aliases, prev symbols, or generic symbols to hgnc identifiers.**

#### WikiPathways all and human lists
1. Downloaded http://www.pathvisio.org/data/bots/gmt/wikipathways.gmt
2. Extracted Homo sapiens subset
3. Used Biomart's ID Converter to get HGNC symbols (or Associated gene names) to then generate two files:
  * hgnc_list_wp_human.txt
  * hgnc_list_wp_all.txt
4. These were made all uppercase and unique
5. Then aliases and prior names were included by mapping to hgnc table (above)
6. Similar processing was done to add generic and unhyphenated entries as well
7. Saved as txt files for ID lookup script
8. Open in TextWrangler to switch linefeed to "Unix(LF)" to work with php scripts


