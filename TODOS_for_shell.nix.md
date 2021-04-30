# TODOS for shell.nix

## take a look at using [xeus-python](https://github.com/jupyter-xeus/xeus-python#what-are-the-advantages-of-using-xeus-python-over-ipykernel-ipython-kernel)

It supports the jupyterlab debugger. But it's not packaged for nixos yet.

## Clean up how to specify extensions

### Types of extensions:

- Jupyter lab extensions
- Jupyter server extensions
- notebook extensions
- bundler extensions (not sure what these are)
- Python magics (not really extensions)

Also, we need to specify CLI dependencies for any/all of the above.

## Look at how to properly auto-fill whatever is needed for the following:

- iPython.packages
- jupyterEnvironment.extraPackages
- jupyterEnvironment.extraJupyterPath
- jupyterEnvironment.extraInputsFrom

Also, I want to be able to run my python from a notebook as well as from the command line.

## Clean up how to specify R deps

I have installed an extension that formats code on save. I think it's a
server extensions. To format R code, the formatter appears to rely on the
Python library 'rpy2' as well as the R pkg 'formatR'.
I also have an extension for LSP capabilities. To make it work with R,
I use the R pkg 'languageserver'.

Is it possible to specify these via extraJupyterPath or extraInputsFrom? I
haven't managed to do it, but it should be possible. I tried adding the
following to extraJupyterPath, but none of these seemed to do it:

- `"${pkgs.R}/lib/R"`
- `"${pkgs.R}/lib/R/library"`
- `"${pkgs.rPackages.formatR}/library"`
- `"${pkgs.rPackages.languageserver}/library"`

TODO: Automatically detect which packages need to be specified for extraInputsFrom.
For now, I just manually specify the deps for nbconvert:

```
extraInputsFrom = p: [ p.pkgs.pandoc p.pkgs.texlive.combined.scheme-full ];
```

These were some attempts that did not work:

```
extraInputsFrom = p: [ pythonEnv.pkgs.nbconvert ];
```

```
extraInputsFrom = p: [ p.pythonPackages.nbconvert ];
```

```
extraInputsFrom = p: p.pythonPackages.nbconvert.propagatedBuildInputs;
```

```
extraInputsFrom = p: pythonEnv.pkgs.nbconvert.propagatedBuildInputs;
```

extraInputsFrom as specified in one of the lines above gave an error when using direnv:

> ./.envrc:109: Sourcing: command not found

This is presumably because the dump.env file
./.direnv/wd-86452ccdf0879f88e537141a4809226d/dump.env
is modified when extraInputsFrom has a python package, with the following lines being added:

> Sourcing python-remove-tests-dir-hook
> Sourcing python-catch-conflicts-hook.sh
> Sourcing python-remove-bin-bytecode-hook.sh
> Sourcing setuptools-build-hook
> Using setuptoolsBuildPhase
> Sourcing pip-install-hook
> Using pipInstallPhase
> Sourcing python-imports-check-hook.sh
> Using pythonImportsCheckPhase
> Sourcing python-namespaces-hook

## Rename directory variables to match what Jupyter uses

- https://jupyter.readthedocs.io/en/latest/use/jupyter-directories.html
- https://jupyterlab.readthedocs.io/en/stable/user/directories.html#jupyterlab-application-directory
- https://jupyter-notebook.readthedocs.io/en/stable/config.html
- https://jupyter-server.readthedocs.io/en/latest/search.html?q=jupyter_server_config.json
- https://jupyterlab.readthedocs.io/en/stable/user/directories.html

## Errors I have sometimes seen:

> TODO: ./.envrc:109: Sourcing: command not found

> TODO: @krassowski/jupyterlab-lsp:signature settings schema could not be found and was not loaded

If JUPYTER_DATA_DIR is made immutable, I get the following error:

> Unexpected error while saving file: Untitled.ipynb HTTP 500: Internal Server Error
> (Unexpected error while saving file: Untitled.ipynb [Errno 30] Read-only file system: '/nix/store/rjcbrkd1br3d4kckw1m1ppn9ksv6sm0c-my-share-jupyter-0.0.0/notebook_secret')

I also got an error when I created an R ipynb file and tried saving it:

> File Save Error for Untitled1.ipynb

> Unexpected error while saving file: Untitled1.ipynb HTTP 500: Internal Server Error (Unexpected error while saving file: Untitled1.ipynb attempt to write a readonly database)

That error is possibly because this file changes when we create a new notebook:

.share/jupyter/nbsignatures.db

To identify which files must be mutable, make all dirs mutable and then:

```
newer .share
find .share/ -newermt '2021-04-12 19:00'
```

or

```
find .share/ -newer .share/jupyter/nbextensions/jupytext/jupytext_menu.png
```

It will yield a list similar to this:

- .share/jupyter/nbconvert/templates
- .share/jupyter/notebook_secret
- .share/jupyter/nbsignatures.db
- .share/jupyter/runtime/jupyter_cookie_secret
- .share/jupyter/runtime/jpserver-26238.json

When the R or Python kernel are launched, these will be added/modified:

- .share/jupyter/runtime/kernel-87d047eb-f646-473a-9f17-fac7fcfe7d75.json
- .share/jupyter/runtime/jpserver-26238-open.html
- .share/jupyter/config/lab/user-settings/@jupyterlab/application-extension/sidebar.jupyterlab-settings
- .share/jupyter/config/lab/workspaces/default-37a8.jupyterlab-workspace

## I was getting the following error message:

> Generating grammar tables from /nix/store/sr8r3k029wvgdbv2zr36wr976dk1lya6-python3-3.8.7-env/lib/python3.8/site-packages/blib2to3/Grammar.txt
> Writing grammar tables to /home/ariutta/.cache/black/20.8b1/Grammar3.8.7.final.0.pickle
> Writing failed: [Errno 2] No such file or directory: '/home/ariutta/.cache/black/20.8b1/tmppem8fqj6'

I made it go away by manually adding the directory, but shouldn't this be automatic?

```
mkdir -p /home/ariutta/.cache/black/20.8b1/
```

## Some useful Nix queries:

```
nix-store -q --roots /nix/store/93hc8xfc1krv8ab2wi1z246q415iaaw5-python3.8-rpy2-3.4.1
```

```
nix-store -q --referrers /nix/store/93hc8xfc1krv8ab2wi1z246q415iaaw5-python3.8-rpy2-3.4.1
```

```
for x in $(ls -1 /nix/store | grep rpy2); do echo ""; echo "/nix/store/$x"; sudo nix-store -q --roots /nix/store/"\$x"; done
```

## for code formatting, compare nb_black with jupyterlab-code-formatter.

One difference:

nb_black is an IPython Magic (%), whereas
jupyterlab-code-formatter is a combo lab & server extension.

https://github.com/ryantam626/jupyterlab_code_formatter

For JupyterLab, call nb_black w/ %load_ext lab_black
https://pypi.org/project/nb-black/
https://github.com/dnanhkhoa/nb_black
