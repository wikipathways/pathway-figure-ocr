# xpm2nix: X Package Manager -> Nix

Packages from other package managers like NPM can be converted to make them Nix packages. There are projects out there for doing this for different package managers, e.g.:

- [`poetry2nix`](https://github.com/nix-community/poetry2nix): Poetry (Python) to Nix
- `npm2nix`: NPM (JavaScript) to Nix
- `composer2nix`: Composer (PHP) to Nix
- multiple others...

This directory is a sub-environment to make it easy to specify dependencies from these other package managers as Nix dependencies in the parent directory. Currently, `./node-packages` is using `npm2nix` and `./python-modules` is using `poetry2nix`. Check those directories for specific instructions in adding and updating dependencies.
