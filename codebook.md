# Codebook for Pathway Figure OCR project
The sections below detail the steps taken to generate files and run scripts for this project.

### Install Dependencies
```sh
sudo su - root
nix-env -iA nixos.postgresql
nix-env -iA nixos.python3
nix-env -iA nixos.python36Packages.psycopg2
nix-env -iA nixos.python36Packages.requests
exit
```

## PubMed Central Image Extraction
_These scripts are capable of populating the database with structured paper and figure information for future OCR runs._


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
* figures (id, paperid, filepath, fignumber, caption)

```sh
nix-shell -p 'python36.withPackages(ps: with ps; [ psycopg2 ])'
./load_pmc.py
# Use CTRL-D to exit nix-shell
```

## Optical Character Recognition
_These scripts are capable of reading selected sets of figures from the database and performing individual runs of OCR_

### Read in Files from Database
* figures (filepath)

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

Caution: if you don't specify an `end` value, it'll run until the last figure. Default `start` value is 0.
```sh
nix-shell -p 'python36.withPackages(ps: with ps; [ psycopg2 requests dill ])'
./gcv_pmc.py --start 0 --end 20
# Use CTRL-D to exit nix-shell
```
Note: `gcv_pmc.py` calls `ocr_pmc.py` at the end, passing along args and functions. The `ocr_pmc.py` script then:

* gets an ocr_processor_id corresponding the unique hash of processing parameters
* retrieves all figure rows and steps through rows `start` to `end`
  * runs image pre-processing
  * performs ocr
  * populates `ocr_processors__figures` with ocr_processor_id, figure_id and result
  
```
  Example psql query to select words from result:
  select substring(regexp_replace(ta->>'description', E'[\\n\\r]+',',','g'),1,45) as word from ocr_processors__figures opf, json_array_elements(opf.result::json->'textAnnotations') AS ta ;
```

## Process Results
_These scripts are capable of processing the results from one or more ocr runs previously stored in the database._

### Create/update word tables for all extracted text
```sh
nix-shell -p 'python36.withPackages(ps: with ps; [ psycopg2 ])'
./postprocess.py
# Use CTRL-D to exit nix-shell
```

* Extract words from JSON in `ocr_processors__figures.result`
* Applies normalization (see `normalize.py`)
* populates `words` with unique occurences
* populates `ocr_processors__figures__words` with all figure_id and word_id occurences

### Create/update xref tables for all lexicon "hits"
* xrefs (id, xref)
* figures__xrefs (figure_id, xref, symbol, filepath, ocr_processor_id)

### Collect run stats
* batches__ocr_processors (batch_id, ocr_processor_id)
* batches (timestamp, parameters, paper_count, figure_count,  total_word_gross, total_word_unique, total_xrefs_gross, total_xrefs_unique)

## Generating Files and Initial Tables
#### hgnc lexicon files
1. Download ```protein-coding-gene``` TXT file from http://www.genenames.org/cgi-bin/statistics
2. Import TXT into Excel, first setting all columns to "skip" then explicitly choosing "text" for symbol, alias_symbol, prev_symbol and entrez_id columns during import wizard (to avoid date conversion of SEPT1, etc)
3. Delete rows without entrez_id mappings
4. In separate tabs, expand 'alias symbol' and 'prev symbol' lists into single-value rows, maintaining entrez_id mappings for each row. Used Data>Text to Columns>Other:|>Column types:Text. Delete empty rows. Collapse multiple columns by pasting entrez_id before each column, sorting and stacking. 
5. Set all entries to uppercase and filtered each list for unique (only affected alias and prev)
6. Remove all hyphens. Note that this did not create any duplicate, non-unique cases. 
7. Export as separate CSV files.

#### bioentities lexicon file
1. Starting with this file from our fork of bioentities: https://github.com/wikipathways/bioentities/blob/master/relations.csv. It captures complexes, generic symbols and gene families, e.g., "WNT" mapping to each of the WNT## entrie.
2. Import CSV into Excel, setting identifier columns to import as "text".
3. Make separate tabs for rows with "BE" and "HGNC" as first column value. Add column to "HGNC" tab based on =LOOKUP(B2,be!B2:B116,be!D2:D116). Be sure to sort column B to get correct result. Get rid of #N/A and then copy HGNC column to generate additional pairs. Sort and stack.
3. Set all entries to uppercase, replace underscore with space, remove hyphens and filter for unique.
4. Add entrez_id column via lookup in hgnc lexicon file using =LOOKUP(B2,n_symbol.csv!$B$2:$B$19177,n_symbol.csv!$A$2:$A$19177).
5. Export as CSV file.

#### WikiPathways human lists
1. Download human GMT from http://data.wikipathways.org/current/gmt/
2. Import GMT file into Excel
3. Select complete matrix and name 'matrix' (upper left text field)
4. Insert column and paste this in to A1
  * =OFFSET(matrix,TRUNC((ROW()-ROW($A$1))/COLUMNS(matrix)),MOD(ROW()-ROW($A$1),COLUMNS(matrix)),1,1)
5. Copy equation down to bottom of sheet, e.g., at least to =ROWS(matrix)\*COLUMNS(matrix)
6. Filter out '0', then filter for unique
7. Export as CSV file. 
