# For more info, see
# http://datakurre.pandala.org/2015/10/nix-for-python-developers.html
# https://nixos.org/nixos/nix-pills/developing-with-nix-shell.html
# https://nixos.org/nix/manual/#sec-nix-shell

with builtins;
let
  # Path to the poetry2nix folder.
  poetry2nixPath = builtins.fetchGit {
    url = https://github.com/nix-community/poetry2nix;
    rev = "e72ff71c3cc8bbc708dbc13941888eb08a65f651";
  };

  # Importing overlays
  overlays = [
    # makes poetry2nix available
    (import "${poetry2nixPath}/overlay.nix")
  ];
  pkgs = import <nixpkgs> { inherit overlays; config.allowUnfree = true; };
  poetry2nix = pkgs.poetry2nix;
in
  poetry2nix.mkPoetryEnv {
    projectDir = ./.;
    overrides = poetry2nix.overrides.withDefaults (self: super: {
      aquirdturtle-collapsible-headings = super.aquirdturtle-collapsible-headings.overridePythonAttrs(oldAttrs: {
        nativeBuildInputs = oldAttrs.nativeBuildInputs ++ [
          super.jupyter-packaging
        ];
      });
      jupyter-resource-usage = super.jupyter-resource-usage.overridePythonAttrs(oldAttrs: {
        nativeBuildInputs = oldAttrs.nativeBuildInputs ++ [
          super.jupyter-packaging
        ];
      });
      jupyterlab = super.jupyterlab.overridePythonAttrs(oldAttrs: {
        nativeBuildInputs = oldAttrs.nativeBuildInputs ++ [
          super.jupyter-packaging
        ];
      });
      jupyterlab-code-formatter = super.jupyterlab-code-formatter.overridePythonAttrs(oldAttrs: {
        nativeBuildInputs = oldAttrs.nativeBuildInputs ++ [
          super.jupyter-packaging
        ];
      });
      jupyterlab-drawio = super.jupyterlab-drawio.overridePythonAttrs(oldAttrs: {
        nativeBuildInputs = oldAttrs.nativeBuildInputs ++ [
          super.jupyter-packaging
        ];
      });
      jupyterlab-hide-code = super.jupyterlab-hide-code.overridePythonAttrs(oldAttrs: {
        nativeBuildInputs = oldAttrs.nativeBuildInputs ++ [
          super.jupyter-packaging
        ];
      });
      jupyterlab-system-monitor = super.jupyterlab-system-monitor.overridePythonAttrs(oldAttrs: {
        nativeBuildInputs = oldAttrs.nativeBuildInputs ++ [
          super.jupyter-packaging
        ];
      });
      jupyterlab-topbar = super.jupyterlab-topbar.overridePythonAttrs(oldAttrs: {
        nativeBuildInputs = oldAttrs.nativeBuildInputs ++ [
          super.jupyter-packaging
        ];
      });
      # TODO: jupyterlab-vim & jupyterlab-vimrc aren't installing, so I manually
      # created custom expressions for them and then cancelled them in this file
      jupyterlab-vim = null;
      jupyterlab-vimrc = null;
#      jupyterlab-vim = super.jupyterlab-vim.overridePythonAttrs(oldAttrs: {
#        nativeBuildInputs = oldAttrs.nativeBuildInputs ++ [
#          super.jupyter-packaging
#          super.setuptools
#          super.wheel
#          self.jupyterlab
#        ];
#        propagatedBuildInputs = oldAttrs.propagatedBuildInputs ++ [
#          pkgs.nodejs
#          pkgs.yarn
#        ];
#      });
#      jupyterlab-vimrc = super.jupyterlab-vimrc.overridePythonAttrs(oldAttrs: {
#        nativeBuildInputs = oldAttrs.nativeBuildInputs ++ [
#          super.jupyter-packaging
#          super.setuptools
#          super.wheel
#          self.jupyterlab
#        ];
#        propagatedBuildInputs = oldAttrs.propagatedBuildInputs ++ [
#          pkgs.nodejs
#          pkgs.yarn
#        ];
#      });
      jupyterlab-widgets = super.jupyterlab-widgets.overridePythonAttrs(oldAttrs: {
        nativeBuildInputs = oldAttrs.nativeBuildInputs ++ [
          super.jupyter-packaging
        ];
      });
    });
  }

#  jupyterExtraPython = (pkgs.python3.withPackages (ps: with ps; [ 
#    # Declare all server extensions in here, plus anything else needed.
#
#    jupyterlab
#    
#    jupyter_console
#
#    #-----------------
#    # Language Server
#    #-----------------
#
#    jupyter_lsp
#
#    # Even when it's specified here, we also need to specify it in
#    # jupyterEnvironment.extraPackages for the language server to work for R.
#    # TODO: why?
#    jupyterlab-lsp
#
#    # jupyterlab-lsp also supports other languages:
#    # https://jupyterlab-lsp.readthedocs.io/en/latest/Language%20Servers.html#NodeJS-based-Language-Servers
#
#    python-language-server
#    rope
#    pyflakes
#    mccabe
#    # others also available
#
#    #-----------------
#    # Code Formatting
#    #-----------------
#
#    jupyterlab_code_formatter
#    black
#    isort
#    autopep8
#
#    #-----------------
#    # Other
#    #-----------------
#
#    jupytext
#    jupyter-resource-usage
#    aquirdturtle_collapsible_headings
#
#    # TODO: can we get this to work?
#    #ipywidgets
#
#    # TODO: is this needed here?
#    jupyter_packaging
#  ]));
