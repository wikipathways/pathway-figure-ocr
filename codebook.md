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
Create database:

```
psql
\i database/create_tables.sql 
\q
```
Load filenames (or paths) and extracted content into database

* papers (id, pmcid, title, url)
* figures (id, paperid, filepath, fignumber, caption)

```sh
nix-shell -p 'python36.withPackages(ps: with ps; [ psycopg2 requests dill ])'
./pfocr.py load_figures
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
./pfocr.py gcv_figures --start 0 --end 20
# Use CTRL-D to exit nix-shell
```
Note: This command calls `ocr_pmc.py` at the end, passing along args and functions. The `ocr_pmc.py` script then:

* gets an `ocr_processor_id` corresponding the unique hash of processing parameters
* retrieves all figure rows and steps through rows `start` to `end`
  * runs image pre-processing
  * performs OCR
  * populates `ocr_processors__figures` with `ocr_processor_id`, `figure_id` and `result`
  
```
  Example psql query to select words from result:
  select substring(regexp_replace(ta->>'description', E'[\\n\\r]+',',','g'),1,45) as word from ocr_processors__figures opf, json_array_elements(opf.result::json->'textAnnotations') AS ta ;
```

## Process Results
_These scripts are capable of processing the results from one or more ocr runs previously stored in the database._

### Create/update word tables for all extracted text
-n for normalizations
-m for mutations
```sh
# TODO can the nix-shell line go into run.sh?
nix-shell -p 'python36.withPackages(ps: with ps; [ psycopg2 requests dill ])'
bash run.sh
# Use CTRL-D to exit nix-shell
```

* Extract words from JSON in `ocr_processors__figures.result`
* Applies transforms (see `transforms/*.py`)
* populates `words` with unique occurences of normalized words
* populates `match_attempts` with all `figure_id` and `word_id` occurences

### Create/update xref tables for all lexicon "hits"
* xrefs (id, xref)
* figures__xrefs (ocr_processor_id, figure_id, xref, symbol, unique_wp_hs, filepath)

```
  Example psql query to rank order figures by unique xrefs:
  select figure_id, count(unique_wp_hs) as unique from figures__xrefs where unique_wp_hs = TRUE group by figure_id order by 2 desc;
```

* Export a table view to file. Can only write to /tmp dir; then sftp to download.
```
copy (select * from figures__xrefs) to '/tmp/filename.csv' with csv;
```

#### Exploring results
* Words extracted for a given paper:
```
select pmcid,figure_number,result from ocr_processors__figures join figures on figures.id=figure_id join papers on papers.id=figures.paper_id where pmcid='PMC2780819';
```
* All paper figures for a given word:
```
select pmcid, figure_number, word from match_attempts join words on words.id=word_id join figures on figures.id=figure_id join papers on papers.id=paper_id where word = 'AC' group by pmcid, figure_number,word;
```

### Collect run stats
* batches__ocr_processors (batch_id, ocr_processor_id)
* batches (timestamp, parameters, paper_count, figure_count,  total_word_gross, total_word_unique, total_xrefs_gross, total_xrefs_unique)

## Generating Files and Initial Tables
Do not apply upper() or remove non-alphanumerics during lexicon constuction. These normalizations will be applied in parallel to both the lexicon and extracted words during post-processing.

#### hgnc lexicon files
1. Download ```protein-coding-gene``` TXT file from http://www.genenames.org/cgi-bin/statistics
2. Import TXT into Excel, first setting all columns to "skip" then explicitly choosing "text" for symbol, alias_symbol, prev_symbol and entrez_id columns during import wizard (to avoid date conversion of SEPT1, etc)
3. Delete rows without entrez_id mappings
4. In separate tabs, expand 'alias symbol' and 'prev symbol' lists into single-value rows, maintaining entrez_id mappings for each row. Used Data>Text to Columns>Other:|>Column types:Text. Delete empty rows. Collapse multiple columns by pasting entrez_id before each column, sorting and stacking. 
5. Filter each list for unique pairs (only affected alias and prev)
6. Enter these formulas into columns C and D, next to sorted alias_symbols in order to "tag" all instances of symbols that match more than one entrez. Delete **all** of these instances.
   * `MATCH(B2,B3:B$###,0)` and `MATCH(B2,B$1:B1,0)`, where ### is last row in sheet.
7. Then delete (ignore) all of these instances (i.e., rather than picking one arbitrarily via a unique function)
   * `IF(AND(ISNA(C2),ISNA(D2)),A2,"")` and `IF(AND(ISNA(C2),ISNA(D2)),B2,"")`
8. Export as separate CSV files.

#### bioentities lexicon file
1. Starting with this file from our fork of bioentities: https://raw.githubusercontent.com/wikipathways/bioentities/master/relations.csv. It captures complexes, generic symbols and gene families, e.g., "WNT" mapping to each of the WNT## entries.
2. Import CSV into Excel, setting identifier columns to import as "text". 
3. Delete "isa" column. Add column names: type, symbol, type2, bioentities. Turn column filters on.
4. Filter on 'type' and make separate tabs for rows with "BE" and "HGNC" values. Sort "be" tab by "symbol" (Column B).
5. Add a column to "hgnc" tab based on =VLOOKUP(D2,be!B$2:D$116,3,FALSE). Copy/paste B and D into new tab and copy/paste-special B and E to append the list. Sort bioentities and remove rows with #N/A.
6. Copy f_symbol tab (from hgnc protein-coding_gene workbook) and sort symbol column. Then add entrez_id column to bioentities via lookup on hgnc symbol using =LOOKUP(A2,n_symbol.csv!$B$2:$B$19177,n_symbol.csv!$A$2:$A$19177).
7. Copy/paste-special columns of entrez_id and bioentities into new tab. Filter for unique pairs.
8. Export as CSV file.

#### WikiPathways human lists
1. Download human GMT from http://data.wikipathways.org/current/gmt/
2. Import GMT file into Excel
3. Select complete matrix and name 'matrix' (upper left text field)
4. Insert column and paste this in to A1
  * =OFFSET(matrix,TRUNC((ROW()-ROW($A$1))/COLUMNS(matrix)),MOD(ROW()-ROW($A$1),COLUMNS(matrix)),1,1)
5. Copy equation down to bottom of sheet, e.g., at least to =ROWS(matrix)\*COLUMNS(matrix)
6. Filter out '0', then filter for unique
7. Export as CSV file. 
