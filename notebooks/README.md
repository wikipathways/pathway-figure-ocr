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
