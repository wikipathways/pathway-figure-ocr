# Pathway Figure OCR

The goal of this project is to extract identifiable genes, proteins and metabolites from published pathway figures. In addition to all the code for assembling and running the Pathway Figure OCR pipeline, this repo contains scripts specific to the QC, analysis and figure generation involved in our publications of the work. Here we document a few of the key files and folders relevant to each paper:

- [25 Years of Pathway Figures (BioRxiv 2020)](https://www.biorxiv.org/content/10.1101/2020.05.29.124503v1)

  - Interactive search tool for 65k pathway figures and their gene content: [shiny app](https://gladstone-bioinformatics.shinyapps.io/shiny-25years) and [code](shiny-25years)
  - NIH Figshare of identified pathway figures and OCR results as RDS datasets: [collection](https://doi.org/10.35092/yhjc.c.5005697)
  - UpSet plot of top text and figure genes: [script](pfocr_qc.R#L681)
  - Pie chart data for top disease terms for text and figure genes: [script](pfocr-gmt-enrich.R#L329)
  - Overlap matrix for Hippo Signaling pathway figure genes: [script](matrix-visualization.R)
  - Machine learning progression plots: [script](pfocr_qc.R#L154)
  - Local database name: `pfocr20200224`

- [Identifying Genes in Published Pathway Figure Images (BioRxiv 2018)](https://www.biorxiv.org/content/10.1101/379446v1)
  - Performance assessment figures: [folder](performance)
  - Local database name: `pfocr2018121717`

This work is supported by NIGMS, [R01GM100039](https://app.dimensions.ai/details/grant/grant.2521530)

## Install

Warning: this project is still in development and is not ready for production or even dev releases by external teams. So, don't expect things to work without some troubleshooting :)
Contact us via [Issues](https://github.com/wikipathways/pathway-figure-ocr/issues) if you're interested in contributing to the development. All our code is open source.

1. Install [Nix](https://nixos.org/nixos/nix-pills/install-on-your-running-system.html#idm140737316672400)
2. Clone this repo: `git clone https://github.com/wikipathways/pathway-figure-ocr.git`
3. Enter environment: `cd pathway-figure-ocr && nix-shell`
4. Launch Jupyter: `jupyter lab` (automatically opens notebook in browser)

## Pipeline

The Jupyter Notebooks used to run the PFOCR pipeline are all in `./notebooks`. Run them in the following order:

1. [`pfocr_fetch.R.ipynb`](https://github.com/wikipathways/pathway-figure-ocr/blob/master/notebooks/pfocr_fetch.R.ipynb)
2. [`get_figures.ipynb`](https://github.com/wikipathways/pathway-figure-ocr/blob/master/notebooks/get_figures.ipynb)
3. [`gcv_automl.ipynb`](https://github.com/wikipathways/pathway-figure-ocr/blob/master/notebooks/gcv_automl.ipynb)
4. [`gcv_ocr.ipynb`](https://github.com/wikipathways/pathway-figure-ocr/blob/master/notebooks/gcv_ocr.ipynb)
5. [`get_lexicon.ipynb`](https://github.com/wikipathways/pathway-figure-ocr/blob/master/notebooks/get_lexicon.ipynb): note that we actually just re-used the `20200224` lexicon for `20210515`, so we didn't really finish this file.
6. [`pp_classic.ipynb`](https://github.com/wikipathways/pathway-figure-ocr/blob/master/notebooks/pp_classic.ipynb)
7. [`merge_2020_2021.ipynb`](https://github.com/wikipathways/pathway-figure-ocr/blob/master/notebooks/merge_2020_2021.ipynb): this was just for the merge of `20200224` and `20210515`. Obviously, it would require being updated for any other merge. Note this notebook is also where we get the metadata for the papers.

Note that we used a database for `20200224` but not for `20210515`. Any future runs or merges will probably not need to use the old database.

## Internal Notes

### xpm2nix

In `./xpm2nix`, you'll find packages from external package manager(s) made available as Nix packages. `xpm` is just an abbreviation we made up to refer to any e**X**ternal **P**ackage **M**anager.

#### For Python, we're using poetry2nix.

```
cd xpm2nix/python-modules
```

To add a package:

```
poetry add --lock jupytext
```

To update packages:

```
poetry update --lock
```

#### For JavaScript / Node.js, we're using node2nix.

```
cd xpm2nix/node-packages
```

To add a package:

```
npm install --package-lock-only --save @arbennett/base16-gruvbox-dark
```

To update packages:

```
./update
```
