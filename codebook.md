# Codebook for Pathway Figure OCR project
The sections below detail the steps taken to generate files and run scripts for this project.

### Install Dependencies
```sh
sudo su - root
nix-env -iA nixos.postgresql
nix-env -iA nixos.python3
nix-env -iA nixos.python36Packages.psycopg2
exit
```

## PubMed Central Image Extraction

This url returns >77k figures from PMC articles matching "signaling pathways". Approximately 80% of these are actually pathway figures. These make a reasonably efficient source of sample figures to test methods. *Consider other search terms and other sources when scaling up.*

```
http://www.ncbi.nlm.nih.gov/pmc/?term=signaling+pathway&report=imagesdocsum
```

### Scrape HTML
For sample sets you can simply save dozens of pages of results and quickly get 1000s of pathway figures. *Consider automating this step when scaling up.*

```
Set Display Settings: to max (100)
Save raw html to designated folder, e.g., pmc/20150501/raw_html
```

Next, configure and run this php script to generated annotated sets of image and html files.

```
php pmc_image_parse.php
```

* depends on simple_html_dom.php
* outputs images as "PMC######__<filename>.<ext>
* outputs caption as "PMC######__<filename>.<ext>.html

*Consider loading caption information directly into database and skip exporting this html file*

These files are exported to a designated folder, e.g., pmc/20150501/images_all

### Prune Images
Another manual step here to increase accuracy of downstream counts. Make a copy of the images_all dir, renaming to images_pruned. View the extracted images in Finder, for example, and delete pairs of files associated with figures that are not actually pathways. In this first sample run, ~20% of images were pruned away. The most common non-pathway figures wer of gel electrophoresis runs. *Consider automated ways to either exclude gel figures or select only pathway images to scale this step up.*

### Load into Database
Load filenames (or paths) and extracted content into database

* papers (id, pmcid, title, url)
* figures (id, paperid, path2img, fignumber, caption)

```sh
nix-shell -p 'python36.withPackages(ps: with ps; [ psycopg2 ])'
python3 /home/pfocr/pathway-figure-ocr/load_pmc.py
# Use CTRL-D to exit nix-shell
```

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
#### hgnc lexicon files
1. Downloaded ```protein-coding-gene``` TXT file from http://www.genenames.org/cgi-bin/statistics
2. Imported TXT into Excel, first setting all columns to "skip" then explicitly choosing "text" for symbol, alias_symbol, prev_symbol and entrez_id columns during import wizard (to avoid date conversion of SEPT1, etc)
3. Delete rows without entrez_id mappings
4. In separate tabs, expanded 'alias symbol' and 'prev symbol' lists into single-value rows, maintaining entrez_id mappings for each row. Used Data>Text to Columns>Other:|>Column types:Text. Deleted empty rows. Collapsed multiple columns by pasting entrez_id before each column, sorting and stacking. 
5. Set all entries to uppercase and filtered each list for unique (only affected alias and prev)
6. Removed all hyphens. Note that this did not create any duplicate, non-unique cases. 
7. Exported as separate CSV files.

#### bioentities lexicon file
1. Starting with this file from our fork of bioentities: https://github.com/wikipathways/bioentities/blob/master/relations.csv. It captures complexes, generic symbols and gene families, e.g., "WNT" mapping to each of the WNT## entrie.
2. Imported CSV into Excel, setting identifier columns to import as "text".
3. Made separate tabs for rows with "BE" and "HGNC" as first column value. Add column to "HGNC" tab based on =LOOKUP(B2,be!B2:B116,be!D2:D116). Be sure to sort column B to get correct result. Get rid of #N/A and then copy HGNC column to generate additional pairs. Sort and stack.
3. Set all entries to uppercase, replace underscore with space, remove hyphens and filter for unique.
4. Add entrez_id column via lookup in hgnc lexicon file using =LOOKUP(B2,n_symbol.csv!$B$2:$B$19177,n_symbol.csv!$A$2:$A$19177).
5. Exported as CSV file.

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


