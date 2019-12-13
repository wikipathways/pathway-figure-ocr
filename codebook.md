# Codebook for Pathway Figure OCR project

The sections below detail the steps taken to generate files and run scripts for this project.

### Install Dependencies

[Nix](https://nixos.org/nixos/nix-pills/install-on-your-running-system.html#idm140737316672400)

## PubMed Central Image Extraction

_These scripts are capable of populating the database with structured paper and figure information for future OCR runs._

This url returns >90k figures from PMC articles matching "signaling pathways". Approximately 80% of these are actually pathway figures. These make a reasonably efficient source of sample figures to test methods. _Consider other search terms and other sources when scaling up._

```
http://www.ncbi.nlm.nih.gov/pmc/?term=signaling+pathway&report=imagesdocsum&dispmax=100
```

You can add publication dates to the query with additional terms. Note the use of a colon for date ranges.

```
https://www.ncbi.nlm.nih.gov/pmc/?term=signaling+pathway+AND+2018+[pdat]&report=imagesdocsum&dispmax=100
https://www.ncbi.nlm.nih.gov/pmc/?term=signaling+pathway+AND+2016+:+2018+[pdat]&report=imagesdocsum&dispmax=100
```

### Scrape HTML

For sample sets you can simply save dozens of pages of results and quickly get 1000s of pathway figures. _Consider automating this step when scaling up._

```
Save raw html to designated folder, e.g., pmc/20150501/rawhtml
```

Next, configure and run this php script to generated annotated sets of image and html files.

```
php pmc_image_parse.php
```

* depends on simple_html_dom.php
* outputs images as "PMC######\_\_<filename>.<ext>
* outputs caption as "PMC######\_\_<filename>.<ext>.html

_Consider loading caption information directly into database and skip exporting this html file_

These files are exported to a designated folder, e.g., pmc/20150501/images

### Prune Images

Another manual step here to increase accuracy of downstream counts. Make a copy of the ```images``` dir, renaming to ```images_pruned```. View the extracted images in Finder, for example, and delete pairs of files associated with figures that are not actually pathways. In this first sample run, ~20% of images were pruned away. The most common non-pathway figures were of gel electrophoresis runs. _Consider automated ways to either exclude gel figures or select only pathway images to scale this step up._

### Load into Database

Before any of these steps, be sure you've entered the nix-shell:

```
nix-shell
```

Create database and load pmc and organism data. To get the data, see sections
`gene2pubmed, pmc2pmid & organism2pubmed` and
`gene2pubtator & organism2pubtator` below. Change database name, if desired, in
the sql file and the example below. Then run:

```
psql -f database/create_tables.sql
psql pfocr20191102 -f database/load_data.sql
```

Load figure data:

First time (update with your image dir):

```sh
./pfocr/pfocr.py load_figures ../pmc/20181216/images/
```

After first time, use this to copy everything:

```sh
sh ./copy_tables.sh
```

Or this to copy everything except the previously loaded figures:

```sh
sh copy_all_except_figures.sh 
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

Enter nix-shell:

```
nix-shell
```

Caution: if you don't specify a `limit` value, it'll run until the last figure.

```sh
./pfocr/pfocr.py ocr pfocr2018121717 gcv --preprocessor noop --limit 20
```

Note: This command calls `ocr_pmc.py` at the end, passing along args and functions. The `ocr_pmc.py` script then:

* gets an `ocr_processor_id` corresponding the unique hash of processing parameters
* retrieves all figure rows and steps through rows

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

Enter nix-shell:

```
nix-shell
```

```sh
bash run.sh
```

* Extract words from JSON in `ocr_processors__figures.result`
* Applies transforms (see `transforms/*.py`)
* populates `words` with unique occurences of normalized words
* populates `match_attempts` with all `figure_id` and `word_id` occurences

### Create/update xref tables for all lexicon "hits"

* xrefs (id, xref)
* figures\_\_xrefs (ocr_processor_id, figure_id, xref, symbol, unique_wp_hs, filepath)

```
  Example psql query to rank order figures by unique xrefs:
  select figure_id, count(unique_wp_hs) as unique from figures__xrefs where unique_wp_hs = TRUE group by figure_id order by 2 desc;
```

* Export a table view to file. Can only write to /tmp dir; then sftp to download.

```
copy (select * from figures__xrefs) to '/tmp/filename.csv' with csv;
```

or

```
copy (\i database/pubtator_gene_matches.sql) to '/tmp/filename.csv' with csv;
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

* batches\_\_ocr_processors (batch_id, ocr_processor_id)
* batches (timestamp, parameters, paper_count, figure_count, total_word_gross, total_word_unique, total_xrefs_gross, total_xrefs_unique)

## Generating Files and Initial Tables

Do not apply upper() or remove non-alphanumerics during lexicon constuction. These normalizations will be applied in parallel to both the lexicon and extracted words during post-processing.

#### hgnc lexicon files

1.  Download `protein-coding-gene` TXT file from http://www.genenames.org/cgi-bin/statistics
2.  Import TXT into Excel, first setting all columns to "skip" then explicitly choosing "text" for symbol, alias_symbol, prev_symbol and entrez_id columns during import wizard (to avoid date conversion of SEPT1, etc)
3.  Delete rows without entrez_id mappings
4.  In separate tabs, expand 'alias symbol' and 'prev symbol' lists into single-value rows, maintaining entrez_id mappings for each row. Used Data>Text to Columns>Other:|>Column types:Text. Delete empty rows. Collapse multiple columns by pasting entrez_id before each column, sorting and stacking.
5.  Filter each list for unique pairs (only affected alias and prev)
6.  For **prev** and **alias**, only keep symbols of 3 or more characters, using:
    * `IF(LEN(B2)<3,"",B2)`
7.  Enter these formulas into columns C and D, next to sorted **alias** in order to "tag" all instances of symbols that match more than one entrez. Delete _all_ of these instances.
    * `MATCH(B2,B3:B$###,0)` and `MATCH(B2,B$1:B1,0)`, where ### is last row in sheet.
8.  Then delete (ignore) all of these instances (i.e., rather than picking one arbitrarily via a unique function)
    * `IF(AND(ISNA(C2),ISNA(D2)),A2,"")` and `IF(AND(ISNA(C2),ISNA(D2)),B2,"")`
9.  Export as separate CSV files.

#### bioentities lexicon file

1.  Starting with this file from our fork of bioentities: https://raw.githubusercontent.com/wikipathways/bioentities/master/relations.csv. It captures complexes, generic symbols and gene families, e.g., "WNT" mapping to each of the WNT## entries.
2.  Import CSV into Excel, setting identifier columns to import as "text".
3.  Delete "isa" column. Add column names: type, symbol, type2, bioentities. Turn column filters on.
4.  Filter on 'type' and make separate tabs for rows with "BE" and "HGNC" values. Sort "be" tab by "symbol" (Column B).
5.  Add a column to "hgnc" tab based on =VLOOKUP(D2,be!B$2:D$116,3,FALSE). Copy/paste B and D into new tab and copy/paste-special B and E to append the list. Sort bioentities and remove rows with #N/A.
6.  Copy f_symbol tab (from hgnc protein-coding_gene workbook) and sort symbol column. Then add entrez_id column to bioentities via lookup on hgnc symbol using =LOOKUP(A2,n_symbol.csv!$B$2:$B$19177,n_symbol.csv!$A$2:$A$19177).
7.  Copy/paste-special columns of entrez_id and bioentities into new tab. Filter for unique pairs.
8.  Export as CSV file.

#### WikiPathways human lists

1.  Download human GMT from http://data.wikipathways.org/current/gmt/
2.  Import GMT file into Excel
3.  Select complete matrix and name 'matrix' (upper left text field)
4.  Insert column and paste this in to A1

* =OFFSET(matrix,TRUNC((ROW()-ROW($A$1))/COLUMNS(matrix)),MOD(ROW()-ROW($A$1),COLUMNS(matrix)),1,1)

5.  Copy equation down to bottom of sheet, e.g., at least to =ROWS(matrix)\*COLUMNS(matrix)
6.  Filter out '0', then filter for unique
7.  Export as CSV file.

### organism names from taxdump

Taxonomy names file (names.dmp):
* `tax_id`: the id of node associated with this name
* `name_txt`: name itself
* `unique name`: the unique variant of this name if name not unique
* `name class`: synonym, common name, ...

```
wget ftp://ftp.ncbi.nih.gov/pub/taxonomy/taxdump.tar.gz
tar -xzf taxdump.tar.gz names.dmp
sed -r 's/\t\|$//g' names.dmp |\
	sed -r 's/\t\|\t/\t/g' |\
	sort -u > organism_names.tsv
rm taxdump.tar.gz names.dmp
```

### gene2pubmed, pmc2pmid & organism2pubmed

```
wget ftp://ftp.ncbi.nlm.nih.gov/gene/DATA/gene2pubmed.gz
gunzip gene2pubmed.gz
mv gene2pubmed gene2pubmed.tsv

head -n 1 gene2pubmed.tsv | cut -f 1,3 > organism2pubmed.tsv
tail -n +2 gene2pubmed.tsv | cut -f 1,3 | sort -u >> organism2pubmed.tsv

wget ftp://ftp.ncbi.nlm.nih.gov/pub/pmc/PMC-ids.csv.gz
gunzip PMC-ids.csv.gz
```

### gene2pubtator & organism2pubtator

```
wget ftp://ftp.ncbi.nlm.nih.gov/pub/lu/PubTator/gene2pubtator.gz
gunzip gene2pubtator.gz
# There can be multiple genes per row. Reshape wide -> long.
awk -F '\t' -v OFS='\t' '{split($2,a,/,|;/); for(i in a) print $1,a[i],$3,$4}' gene2pubtator > gene2pubtator.tsv
head -n 1 gene2pubtator.tsv | cut -f 1,2 > gene2pubtator_uniq.tsv
tail -n +2 gene2pubtator.tsv | cut -f 1,2 | sort -u >> gene2pubtator_uniq.tsv
rm gene2pubtator

wget ftp://ftp.ncbi.nlm.nih.gov/pub/lu/PubTator/species2pubtator.gz
gunzip species2pubtator.gz
# sed: Remove leading zeros from pmids.
# awk: Reshape wide -> long to handle when multiple organisms per row.
sed -E 's/^0*//g' species2pubtator |\
	awk -F '\t' -v OFS='\t' '{split($2,a,/,|;/); for(i in a) print $1,a[i],$3,$4}' > organism2pubtator.tsv
head -n 1 organism2pubtator.tsv | cut -f 1,2 > organism2pubtator_uniq.tsv
tail -n +2 organism2pubtator.tsv | cut -f 1,2 | sort -u >> organism2pubtator_uniq.tsv
rm species2pubtator
```

### Running Database Queries

See database/README.md
