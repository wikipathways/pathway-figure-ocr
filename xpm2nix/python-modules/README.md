# Dependencies from PyPi

I am using [`poetry2nix`](https://github.com/nix-community/poetry2nix) for this.

To add a new dependency:

```
poetry add --lock jupytext
```

with an optional dependency:

```
poetry add --lock pandas[xlrd]
```

That will add `jupytext` to `pyproject.toml` as well as `poetry.lock`.

Note: if you update `pyproject.toml` manually, be sure to also update `poetry.lock`:

```
poetry lock
```

## For more info on working with Python + Nix:

- http://datakurre.pandala.org/2015/10/nix-for-python-developers.html
- https://nixos.org/nixos/nix-pills/developing-with-nix-shell.html
- https://nixos.org/nix/manual/#sec-nix-shell
