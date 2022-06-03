# PFOCR notebooks

1. `pyenv shell 3.9.12`
2. `poetry env use python3.9`
3. `poetry lock`
4. `poetry install`
5. `poetry shell`
6. `jupyter lab`

For information on which order these notebooks are to be run, check out the [`Pipeline` section of the main README](https://github.com/wikipathways/pathway-figure-ocr#pipeline).

As soon as the development solidifies on these, we'll probably want to convert much of this code back to scripts, not notebooks.

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
