with builtins;
let
  #4
  # this corresponds to notebook_dir (impure)
  rootDirectoryImpure = toString ./.;
  shareDirectoryImpure = "${rootDirectoryImpure}/share-jupyter";
  jupyterlabDirectoryImpure = "${rootDirectoryImpure}/share-jupyter/lab";
  # Path to the JupyterWith folder.
  jupyterWithPath = builtins.fetchGit {
    url = https://github.com/tweag/jupyterWith;
    rev = "35eb565c6d00f3c61ef5e74e7e41870cfa3926f7";
  };

  myoverlay = import (builtins.fetchGit {
    url = https://github.com/ariutta/mynixpkgs;
    rev = "49f0c1bcdc79a5f6b3dd6f58c988e8c90d024fb1";
    ref = "overlay";
  });

  overlays = [
    myoverlay
    # jupyterWith overlays
    # Only necessary for Haskell kernel
    (import "${jupyterWithPath}/nix/haskell-overlay.nix")
    # Necessary for Jupyter
    (import "${jupyterWithPath}/nix/python-overlay.nix")
    (import "${jupyterWithPath}/nix/overlay.nix")
  ];

  # Your Nixpkgs snapshot, with JupyterWith packages.
  pkgs = import <nixpkgs> { inherit overlays; };

  jupyterExtraPython = (pkgs.python3.withPackages (ps: with ps; [ 
    # Declare all server extensions in here, plus anything else needed.

    jupyterlab

    #-----------------
    # Language Server
    #-----------------

    jupyter_lsp

    # Even when it's specified here, we also need to specify it in
    # jupyterEnvironment.extraPackages for the LS for R to work.
    # TODO: why?
    jupyterlab-lsp
    # jupyterlab-lsp also supports other languages:
    # https://jupyterlab-lsp.readthedocs.io/en/latest/Language%20Servers.html#NodeJS-based-Language-Servers

    # The formatter for Python code is working, but formatR for R code is not.

    python-language-server
    rope
    pyflakes
    mccabe
    # others also available

    #-----------------
    # Code Formatting
    #-----------------

    jupyterlab_code_formatter
    black
    isort
    autopep8

    #-----------------
    # Other
    #-----------------

    jupytext
    jupyter-resource-usage
    aquirdturtle_collapsible_headings

    # TODO: is this needed here?
    jupyter_packaging
  ]));
  jupyter = pkgs.jupyterWith;

  #########################
  # R
  #########################

  myRPackages = p: with p; [
    #------------
    # for Jupyter
    #------------
    formatR
    languageserver

    #----------------
    # not for Jupyter
    #----------------
    pacman

    tidyverse
    # tidyverse includes the following:
    # * ggplot2 
    # * purrr   
    # * tibble  
    # * dplyr   
    # * tidyr   
    # * stringr 
    # * readr   
    # * forcats 

    knitr
  ];

  myR = [ pkgs.R ] ++ (myRPackages pkgs.rPackages);

  irkernel = jupyter.kernels.iRWith {
    # Identifier that will appear on the Jupyter interface.
    name = "pkgs_on_IRkernel";
    # Libraries to be available to the kernel.
    packages = myRPackages;
    # Optional definition of `rPackages` to be used.
    # Useful for overlaying packages.
    rPackages = pkgs.rPackages;
  };

#  # It appears juniper doesn't work anymore
#  juniper = jupyter.kernels.juniperWith {
#    # Identifier that will appear on the Jupyter interface.
#    name = "JuniperKernel";
#    # Libraries (R packages) to be available to the kernel.
#    packages = myRPackages;
#    # Optional definition of `rPackages` to be used.
#    # Useful for overlaying packages.
#    # TODO: why not just do this in overlays above?
#    #rPackages = pkgs.rPackages;
#  };

  #########################
  # Python
  #########################

  # TODO: take a look at xeus-python
  # https://github.com/jupyter-xeus/xeus-python#what-are-the-advantages-of-using-xeus-python-over-ipykernel-ipython-kernel
  # It supports the jupyterlab debugger. But it's not packaged for nixos yet.

  iPython = jupyter.kernels.iPythonWith {
    name = "pkgs_on_IPython";
    packages = p: with p; [
      ##############################
      # Packages to augment Jupyter
      ##############################

      # TODO: nb_black is a 'python magic', not a server extension. Since it is
      # intended only for augmenting jupyter, where should I specify it?
      nb_black

      # TODO: for code formatting, compare nb_black with jupyterlab_code_formatter.
      # One difference:
      # nb_black is an IPython Magic (%), whereas
      # jupyterlab_code_formatter is a combo lab & server extension.

      # similar question for nbconvert: where should we specify it?
      nbconvert

      ################################
      # Non-Jupyter-specific packages
      ################################

      numpy
      pandas

      beautifulsoup4
      soupsieve

      seaborn

      requests
      requests-cache

      #google_api_core
      #google_cloud_core
      #google-cloud-sdk
      #google_cloud_testutils
      #google_cloud_automl
      #google_cloud_storage

      # some of these may be needed to make rpy2 work
      simplegeneric
      # tzlocal is needed to make rpy2 work
      tzlocal
      rpy2

      pyahocorasick
      spacy

      unidecode
      homoglyphs
      confusable-homoglyphs

      # Python interface to the libmagic file type identification library
      python_magic
      # python bindings for imagemagick
      Wand
      # Python Imaging Library
      pillow

      # fix encodings
      ftfy

      lxml
      wikidata2df
      skosmos_client
    ];
  };

  jupyterEnvironment =
    jupyter.jupyterlabWith {
      directory = jupyterlabDirectoryImpure;
      kernels = [ iPython irkernel ];
      extraPackages = p: [
        # needed by nbconvert
        p.pandoc
        # see https://github.com/jupyter/nbconvert/issues/808
        #tectonic
        # more info: https://nixos.wiki/wiki/TexLive
        p.texlive.combined.scheme-full

        # TODO: these dependencies are only required when want to build a lab
        # extension from source.
        # Does jupyterWith allow me to specify them as buildInputs?
        p.nodejs
        p.yarn

        # jupyterlab-lsp must be specified here in order for the LSP for R to work.
        # TODO: why isn't it enough that this is specified for jupyterExtraPython?
        pkgs.python3Packages.jupyterlab-lsp

        # Note: has packages for augmenting Jupyter and for other purposes.
        jupyterExtraPython

        ################################
        # non-Jupyter-specific packages
        ################################

        p.imagemagick

        # to run AutoML Vision
        p.google-cloud-sdk

        p.exiftool

        # to get perceptual hash values of images
        # p.phash
        p.blockhash
      ];

      extraJupyterPath = pkgs:
        concatStringsSep ":" [
          "${jupyterExtraPython}/lib/${jupyterExtraPython.libPrefix}/site-packages"
          "${pkgs.rPackages.formatR}/library/formatR/R"
          "${pkgs.rPackages.languageserver}/library/languageserver/R"
        ];
    };
in
  jupyterEnvironment.env.overrideAttrs (oldAttrs: {
    shellHook = oldAttrs.shellHook + ''
    # this is needed in order that tools like curl and git can work with SSL
    if [ ! -f "$SSL_CERT_FILE" ] || [ ! -f "$NIX_SSL_CERT_FILE" ]; then
      candidate_ssl_cert_file=""
      if [ -f "$SSL_CERT_FILE" ]; then
        candidate_ssl_cert_file="$SSL_CERT_FILE"
      elif [ -f "$NIX_SSL_CERT_FILE" ]; then
        candidate_ssl_cert_file="$NIX_SSL_CERT_FILE"
      else
        candidate_ssl_cert_file="/etc/ssl/certs/ca-bundle.crt"
      fi
      if [ -f "$candidate_ssl_cert_file" ]; then
          export SSL_CERT_FILE="$candidate_ssl_cert_file"
          export NIX_SSL_CERT_FILE="$candidate_ssl_cert_file"
      else
        echo "Cannot find a valid SSL certificate file. curl will not work." 1>&2
      fi
    fi
    # TODO: is the following line ever useful?
    #export SSL_CERT_FILE=${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt

    # set SOURCE_DATE_EPOCH so that we can use python wheels
    SOURCE_DATE_EPOCH=$(date +%s)

    export JUPYTERLAB_DIR="${jupyterlabDirectoryImpure}"
    export JUPYTER_CONFIG_DIR="${shareDirectoryImpure}/config"
    export JUPYTER_DATA_DIR="${shareDirectoryImpure}"
    export JUPYTER_RUNTIME_DIR="${shareDirectoryImpure}/runtime"

    # mybinder gave this message when launching:
    # Installation finished!  To ensure that the necessary environment
    # variables are set, either log in again, or type
    # 
    #   . /home/jovyan/.nix-profile/etc/profile.d/nix.sh
    # 
    # in your shell.

    if [ -f /home/jovyan/.nix-profile/etc/profile.d/nix.sh ]; then
       . /home/jovyan/.nix-profile/etc/profile.d/nix.sh
    fi

    mkdir -p "$JUPYTER_DATA_DIR"
    mkdir -p "$JUPYTER_RUNTIME_DIR"

    ##################
    # specify configs
    ##################

    rm -rf "$JUPYTER_CONFIG_DIR"
    mkdir -p "$JUPYTER_CONFIG_DIR"

    # TODO: which of way of specifying server configs is better?
    # 1. jupyter_server_config.json (single file w/ all jpserver_extensions.)
    # 2. jupyter_server_config.d/ (directory holding multiple config files)
    #                            jupyterlab.json
    #                            jupyterlab_code_formatter.json
    #                            ... 

    #----------------------
    # jupyter_server_config
    #----------------------
    # We need to set root_dir in config so that this command:
    #   direnv exec ~/Documents/myenv jupyter lab start
    # always results in root_dir being ~/Documents/myenv.
    # Otherwise, running that command from $HOME makes root_dir be $HOME.
    #
    # TODO: what is the difference between these two:
    # - ServerApp.jpserver_extensions
    # - NotebookApp.nbserver_extensions
    #
    # TODO: what's the point of the following check?
    if [ -f "$JUPYTER_CONFIG_DIR/jupyter_server_config.json" ]; then
      echo "File already exists: $JUPYTER_CONFIG_DIR/jupyter_server_config.json" >/dev/stderr
      exit 1
    fi
    #
    # If I don't include jupyterlab_code_formatter in
    # ServerApp.jpserver_extensions, I get the following error
    #   Jupyterlab Code Formatter Error
    #   Unable to find server plugin version, this should be impossible,open a GitHub issue if you cannot figure this issue out yourself.
    #
    echo '{"ServerApp": {"root_dir": "${rootDirectoryImpure}", "jpserver_extensions":{"nbclassic":true,"jupyterlab":true,"jupyterlab_code_formatter":true}}}' >"$JUPYTER_CONFIG_DIR/jupyter_server_config.json"

    #------------------------
    # jupyter_notebook_config
    #------------------------
    # The packages listed by 'jupyter-serverextension list' come from
    # what is specified in ./config/jupyter_notebook_config.json.
    # Yes, it does appear that 'server extensions' are indeed specified in
    # jupyter_notebook_config, not jupyter_server_config. That's confusing.
    #
    echo '{ "NotebookApp": { "nbserver_extensions": { "jupyterlab": true, "jupytext": true, "jupyter_lsp": true, "jupyterlab_code_formatter": true, "jupyter_resource_usage": true }}}' >"$JUPYTER_CONFIG_DIR/jupyter_notebook_config.json"

    #-------------------
    # widgetsnbextension
    #-------------------
    # Not completely sure why this is needed, but without it, things didn't work.
    mkdir -p "$JUPYTER_CONFIG_DIR/nbconfig/notebook.d"
    echo '{"load_extensions":{"jupyter-js-widgets/extension":true}}' >"$JUPYTER_CONFIG_DIR/nbconfig/notebook.d/widgetsnbextension.json"

    #################################
    # symlink prebuilt lab extensions
    #################################

    rm -rf "$JUPYTER_DATA_DIR/labextensions"
    mkdir -p "$JUPYTER_DATA_DIR/labextensions"

    # Note the prebuilt lab extensions are distributed via PyPI as "python"
    # packages, even though they are really JS, HTML and CSS.
    #
    # Symlink targets may generally use snake-case, but not always.
    #
    # The lab extension code appears to be in two places in the python packge:
    # 1) lib/python3.8/site-packages/snake_case_pkg_name/labextension
    # 2) share/jupyter/labextensions/dash-case-pkg-name
    # These directories are identical, except share/... has file install.json.

    # jupyterlab_hide_code
    #
    # When the symlink target is 'jupyterlab-hide-code' (dash case), the lab extension
    # works, but not when the symlink target is 'jupyterlab_hide_code' (snake_case).
    #
    # When using target share/..., the command 'jupyter-labextension list'
    # adds some extra info to the end:
    #   jupyterlab-hide-code v3.0.1 enabled OK (python, jupyterlab_hide_code)
    # When using target lib/..., we get just this:
    #   jupyterlab-hide-code v3.0.1 enabled OK
    # This difference could be due to the install.json being in share/...
    #
    ln -s "${pkgs.python3Packages.jupyterlab_hide_code}/share/jupyter/labextensions/jupyterlab-hide-code" "$JUPYTER_DATA_DIR/labextensions/jupyterlab-hide-code"

    # @axlair/jupyterlab_vim
    mkdir -p "$JUPYTER_DATA_DIR/labextensions/@axlair"
    ln -s "${pkgs.python3Packages.jupyterlab_vim}/lib/${pkgs.python3.libPrefix}/site-packages/jupyterlab_vim/labextension" "$JUPYTER_DATA_DIR/labextensions/@axlair/jupyterlab_vim"

    # jupyterlab-vimrc
    ln -s "${pkgs.python3Packages.jupyterlab-vimrc}/lib/${pkgs.python3.libPrefix}/site-packages/jupyterlab-vimrc" "$JUPYTER_DATA_DIR/labextensions/jupyterlab-vimrc"

    # @krassowski/jupyterlab-lsp
    mkdir -p "$JUPYTER_DATA_DIR/labextensions/@krassowski"
    ln -s "${pkgs.python3Packages.jupyterlab-lsp}/share/jupyter/labextensions/@krassowski/jupyterlab-lsp" "$JUPYTER_DATA_DIR/labextensions/@krassowski/jupyterlab-lsp"

    # @ryantam626/jupyterlab_code_formatter
    mkdir -p "$JUPYTER_DATA_DIR/labextensions/@ryantam626"
    ln -s "${pkgs.python3Packages.jupyterlab_code_formatter}/share/jupyter/labextensions/@ryantam626/jupyterlab_code_formatter" "$JUPYTER_DATA_DIR/labextensions/@ryantam626/jupyterlab_code_formatter"

    # jupyterlab-drawio
    ln -s "${pkgs.python3Packages.jupyterlab-drawio}/lib/${pkgs.python3.libPrefix}/site-packages/jupyterlab-drawio/labextension" "$JUPYTER_DATA_DIR/labextensions/jupyterlab-drawio"

    # @aquirdturtle/collapsible_headings
    mkdir -p "$JUPYTER_DATA_DIR/labextensions/@aquirdturtle"
    ln -s "${pkgs.python3Packages.aquirdturtle_collapsible_headings}/share/jupyter/labextensions/@aquirdturtle/collapsible_headings" "$JUPYTER_DATA_DIR/labextensions/@aquirdturtle/collapsible_headings"

    # jupyterlab-system-monitor depends on jupyterlab-topbar and jupyter-resource-usage

    # jupyterlab-topbar
    ln -s "${pkgs.python3Packages.jupyterlab-topbar}/lib/${pkgs.python3.libPrefix}/site-packages/jupyterlab-topbar/labextension" "$JUPYTER_DATA_DIR/labextensions/jupyterlab-topbar-extension"

    # jupyter-resource-usage
    mkdir -p "$JUPYTER_DATA_DIR/labextensions/@jupyter-server"
    ln -s "${pkgs.python3Packages.jupyter-resource-usage}/share/jupyter/labextensions/@jupyter-server/resource-usage" "$JUPYTER_DATA_DIR/labextensions/@jupyter-server/resource-usage"

    # jupyterlab-system-monitor
    ln -s "${pkgs.python3Packages.jupyterlab-system-monitor}/lib/${pkgs.python3.libPrefix}/site-packages/jupyterlab-system-monitor/labextension" "$JUPYTER_DATA_DIR/labextensions/jupyterlab-system-monitor"

    if [ ! -d "$JUPYTERLAB_DIR" ]; then
      # We are overwriting everything else, but we only run this section when
      # "$JUPYTERLAB_DIR" is missing, because the build step is time intensive.

      mkdir -p "$JUPYTERLAB_DIR"
      mkdir -p "$JUPYTERLAB_DIR/staging"

      #########################
      # build jupyter lab alone
      #########################

      # Note: we pipe stdout to stderr because otherwise $(cat "$\{dump\}")
      # would contain something that should not be evaluated.
      # Look at 'eval $(cat "$\{dump\}")' in ./.envrc file.

      chmod -R +w "$JUPYTERLAB_DIR/staging/"
      jupyter lab build 1>&2

      ###########################
      # add source lab extensions
      ###########################

      # A source lab extension is a raw JS package, and it must be compiled.

      # https://github.com/arbennett/jupyterlab-themes
      chmod -R +w "$JUPYTERLAB_DIR/staging/"
      jupyter labextension install --no-build @arbennett/base16-gruvbox-dark 1>&2
      chmod -R +w "$JUPYTERLAB_DIR/staging/"
      jupyter labextension install --no-build @arbennett/base16-gruvbox-light 1>&2

      ############################################
      # build jupyter lab w/ source lab extensions
      ############################################

      # It would be nice to be able to just build once here at the end, but the
      # build process appears to fail unless I build once for jupyter lab alone
      # then again after adding source lab extensions.

      chmod -R +w "$JUPYTERLAB_DIR/staging/"
      jupyter lab build 1>&2

      chmod -R -w "$JUPYTERLAB_DIR/staging/"
    fi

    ###########
    # Settings
    ###########

    # Specify a font for the Terminal to make the Powerline prompt look OK.

    # TODO: should we install the fonts as part of this Nix definition?
    # TODO: one setting is '"theme": "inherit"'. Where does it inherit from?
    #       is it @jupyterlab/apputils-extension:themes.theme?

    mkdir -p "$JUPYTERLAB_DIR/settings"
    touch "$JUPYTERLAB_DIR/settings/overrides.json"
    rm "$JUPYTERLAB_DIR/settings/overrides.json"
    echo '{"jupyterlab-vimrc:vimrc": {"imap": [["jk", "<Esc>"]]}, "@jupyterlab/apputils-extension:themes": {"theme": "base16-gruvbox-dark"}, "@jupyterlab/terminal-extension:plugin":{"fontFamily":"Meslo LG S DZ for Powerline,monospace"}}' >"$JUPYTER_DATA_DIR/lab/settings/overrides.json"

    # Setting for tab manager being on the right is something like this:
    # "@jupyterlab/application-extension:sidebar": {"overrides": {"tab-manager": "right"}}
    #
    # "@jupyterlab/extensionmanager-extension:plugin": {"enabled": false}
    #
    '';
  })
