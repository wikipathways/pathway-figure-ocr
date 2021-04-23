To update:

Enter the Nix environment automatically using direnv, or do it manually: `nix-shell ../shell.nix`.

Run the update: `./update`

## Building

The method applied by the `update` script is the best way I've found to build
Jupyter lab extensions in order to convert them from source to prebuilt format.
I've tried multiple ways, some of them listed below. Is there a better way?

### From yarn.lock

Get package.json and yarn.lock, then convert yarn.lock to an NPM formatted file

```
npm shrinkwrap
node2nix -l npm-shrinkwrap.json
```

The result wouldn't build.

Maybe I could convert from yarn.lock to package-lock.json with [synp](https://github.com/imsnif/synp)?

### From the NPM tarball

- get the tarball

```
wget $(npm view @arbennett/base16-gruvbox-dark dist.tarball)
```

- add a missing devDep to package.json

```
"@jupyterlab/builder": "3.0.5",
```

- build

```
jupyter labextension build
```

That didn't work. `jupyter labextension build` only works for the raw source.

### Other attempts?

Could this be useful somehow?

```
nix-build -A tarball
```
