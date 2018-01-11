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
* Produce JSON files
* Load filnames (paths) into database
 * figures (gcv_json)

