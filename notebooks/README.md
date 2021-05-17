# PFOCR in notebooks

## Pipeline order
1. pfocr_fetch.R.ipynb
2. get_figures.ipynb
3. gcv_automl.ipynb
4. gcv_ocr.ipynb
5. get_lexicon.ipynb
6. pp_classic.ipynb



## Other

Full rebuild and check extensions:

```
mkdir -p share-jupyter/lab/staging/ && chmod -R +w share-jupyter/lab/staging/ && rm -rf share-jupyter .direnv/ && direnv allow
```

```
jupyter-serverextension list && jupyter-labextension list
```

Full rebuild and open notebook:

```
ssh nixos 'mkdir -p Documents/pathway-figure-ocr/share-jupyter/lab/staging && chmod -R +w Documents/pathway-figure-ocr/share-jupyter/lab/staging && rm -rf Documents/pathway-figure-ocr/.direnv Documents/pathway-figure-ocr/.virtual_documents Documents/pathway-figure-ocr/share-jupyter' && jupyterlab-connect nixos:Documents/pathway-figure-ocr
```
