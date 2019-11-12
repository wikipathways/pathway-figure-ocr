Pathway Figure OCR
===
The goal of this project is to extract identifyable genes, proteins and metabolites from published pathway figures. See our technical paper on the strategy and status of the work so far:

[Identifying Genes in Published Pathway Figure Images - BioRxiv 2018](https://www.biorxiv.org/content/10.1101/379446v1)

Inputs: currently figures from PMC.
Outputs: currently gene mentions for each figure.

### How to Run
Check out the [codebook](codebook.md) for the current recipe. Be forewarned, however, this project is still in development and is not ready for production or even dev releases. So, don't expect things to work :)

#### Quick Start

```
nix-shell
./pfocr/pfocr.py --help
```

### How to Develop
Contact us by email or via Issues if you're interested in contributing to the development. All our projects are open source.

### Run Tests

```sh
(export PFOCR_DB=pfocr2018121717; cd pfocr; python -m unittest)
```
