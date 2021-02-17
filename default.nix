with builtins;
let
  # this corresponds to notebook_dir (impure)
  rootDirectoryImpure = toString ./.;
  shareDirectoryImpure = "${rootDirectoryImpure}/share-jupyter";
  # Path to the JupyterWith folder.
  jupyterWithPath = builtins.fetchGit {
    url = https://github.com/tweag/jupyterWith;
    rev = "35eb565c6d00f3c61ef5e74e7e41870cfa3926f7";
  };

  # for dev
  #myoverlay = import ../mynixpkgs/overlay.nix;
  # for prod
  myoverlay = import (builtins.fetchGit {
    url = https://github.com/ariutta/mynixpkgs;
    rev = "4cd485f8fc2f43fcefdbdc838558ca9d6c174313";
    ref = "main";
  });

  myspecs = ./specs;

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
    
    jupyter_console

    #-----------------
    # Language Server
    #-----------------

    jupyter_lsp

    # Even when it's specified here, we also need to specify it in
    # jupyterEnvironment.extraPackages for the language server to work for R.
    # TODO: why?
    jupyterlab-lsp

    # jupyterlab-lsp also supports other languages:
    # https://jupyterlab-lsp.readthedocs.io/en/latest/Language%20Servers.html#NodeJS-based-Language-Servers

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

    # TODO: can we get this to work?
    #ipywidgets

    # TODO: is this needed here?
    jupyter_packaging
  ]));
  jupyter = pkgs.jupyterWith;

  #########################
  # R
  #########################

  myRPackages = p: with p; [
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

    feather
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

      lxml
      seaborn
      skosmos_client
      wikidata2df

      ############
      # requests+
      ############
      requests
      requests-cache

      ############
      # Pandas+
      ############
      numpy
      pandas
      pyarrow # needed for pd.read_feather()

      ########
      # rpy2
      ########
      rpy2
      # tzlocal is needed to make rpy2 work
      tzlocal
      # TODO: is simplegeneric also needed?
      simplegeneric

      ##################
      # Parse messy HTML
      ##################
      beautifulsoup4
      soupsieve

      ########
      # Text
      ########

      # for characters that look like each other
      confusable-homoglyphs
      homoglyphs

      # fix encodings
      ftfy

      pyahocorasick
      spacy
      unidecode

      ########
      # Images
      ########

      # Python interface to the libmagic file type identification library
      # I don't think this has anything to do w/ Jupyter magics
      python_magic
      # python bindings for imagemagick
      Wand
      # Python Imaging Library
      pillow

      ########
      # Google
      ########

      #google_api_core
      #google_cloud_core
      #google-cloud-sdk
      #google_cloud_testutils
      #google_cloud_automl
      #google_cloud_storage
    ];
  };

  jupyterEnvironment =
    jupyter.jupyterlabWith {
      directory = "${rootDirectoryImpure}/share-jupyter/lab";
      kernels = [ iPython irkernel ];

      # Add extra packages to the JupyterWith environment
      extraPackages = p: [
        ####################
        # For Jupyter
        ####################

        # labextension
        p.base16-gruvbox-dark-labextension

        # needed by nbconvert
        p.pandoc
        # see https://github.com/jupyter/nbconvert/issues/808
        #tectonic
        # more info: https://nixos.wiki/wiki/TexLive
        p.texlive.combined.scheme-full

        # TODO: these dependencies are only required when we want to build a
        # lab extension from source.
        # Does jupyterWith allow me to specify them as buildInputs?
        p.nodejs
        p.yarn

        # Note: has packages for augmenting Jupyter and for other purposes.
        # TODO: should it be specified here?
        jupyterExtraPython

        # jupyterlab-lsp must be specified here in order for the LSP for R to work.
        # TODO: why isn't it enough that this is specified for jupyterExtraPython?
        pkgs.python3Packages.jupyterlab-lsp

        #############
        # Non-Jupyter
        #############

        p.imagemagick

        # to run AutoML Vision
        p.google-cloud-sdk

        p.exiftool

        # to get perceptual hash values of images
        # p.phash
        p.blockhash
      ] ++ (with pkgs.rPackages; [
        ################################################
        # For server extensions that rely on R or R pkgs
        ################################################
        # TODO: is it possible to specify these via extraJupyterPath instead?
        #       I haven't managed to do it, but it should be possible.
        #       I tried adding the following to extraJupyterPath, but that
        #       didn't seem to do it.
        #"${pkgs.R}/lib/R" 
        #"${pkgs.R}/lib/R/library"
        #"${pkgs.rPackages.formatR}/library"
        #"${pkgs.rPackages.languageserver}/library"

        languageserver

        #----------------
        # code formatting
        #----------------
        formatR
        ## an alternative formatter:
        #styler
        #prettycode # seems to be needed by styler
      ]);

      # Bring all inputs from a package in scope:
      #extraInputsFrom = p: [ ];

      # Make paths available to Jupyter itself, generally for server extensions
      extraJupyterPath = pkgs:
        concatStringsSep ":" [
          "${jupyterExtraPython}/lib/${jupyterExtraPython.libPrefix}/site-packages"
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
        echo "Cannot find a valid SSL certificate file. curl will not work." >&2
      fi
    fi
    # TODO: is the following line ever useful?
    #export SSL_CERT_FILE=${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt

    # set SOURCE_DATE_EPOCH so that we can use python wheels
    SOURCE_DATE_EPOCH=$(date +%s)

    export JUPYTER_DATA_DIR="${shareDirectoryImpure}"
    export JUPYTER_CONFIG_DIR="${shareDirectoryImpure}/config"
    export JUPYTER_RUNTIME_DIR="${shareDirectoryImpure}/runtime"
    export JUPYTERLAB_DIR="${shareDirectoryImpure}/lab"

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

    mkdir -p "${shareDirectoryImpure}"
    mkdir -p "${shareDirectoryImpure}/runtime"

    ##################
    # Specify settings
    ##################

    # Specify a font for the Terminal to make the Powerline prompt look OK.

    # TODO: should we install the fonts as part of this Nix definition?
    # TODO: one setting is '"theme": "inherit"'. Where does it inherit from?
    #       is it @jupyterlab/apputils-extension:themes.theme?

    mkdir -p "${shareDirectoryImpure}/lab/settings"
    if [ -h "${shareDirectoryImpure}/lab/settings/overrides.json" ]; then
      rm "${shareDirectoryImpure}/lab/settings/overrides.json"
    elif [ -f "${shareDirectoryImpure}/lab/settings/overrides.json" ]; then
      echo "Replacing ${shareDirectoryImpure}/lab/settings/overrides.json" >&2
      chmod +w "${shareDirectoryImpure}/lab/settings/overrides.json"
      mv "${shareDirectoryImpure}/lab/settings/overrides.json" "${shareDirectoryImpure}/lab/settings/overrides.json.old"
    fi
    ln -s "${myspecs}/overrides.json" "${shareDirectoryImpure}/lab/settings/overrides.json"

    # for other settings, open Settings > Advanced Settings Editor to take a look.

    ##################
    # specify configs
    ##################

    rm -rf "${shareDirectoryImpure}/config"
    mkdir -p "${shareDirectoryImpure}/config"

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
    # If I don't include jupyterlab_code_formatter in
    # ServerApp.jpserver_extensions, I get the following error
    #   Jupyterlab Code Formatter Error
    #   Unable to find server plugin version, this should be impossible,open a GitHub issue if you cannot figure this issue out yourself.
    #
    if [ -h "${shareDirectoryImpure}/config/jupyter_server_config.json" ]; then
      # if it's a symlink, just delete it
      rm "${shareDirectoryImpure}/config/jupyter_server_config.json"
    elif [ -f "${shareDirectoryImpure}/config/jupyter_server_config.json" ]; then
      echo "Replacing ${shareDirectoryImpure}/config/jupyter_server_config.json" >&2
      chmod +w "${shareDirectoryImpure}/config/jupyter_server_config.json"
      mv "${shareDirectoryImpure}/config/jupyter_server_config.json" "${shareDirectoryImpure}/config/jupyter_server_config.json.old"
    fi
    substitute "${myspecs}/jupyter_server_config.json" "${shareDirectoryImpure}/config/jupyter_server_config.json" --subst-var-by rootDirectoryImpure "${rootDirectoryImpure}"

    #------------------------
    # jupyter_notebook_config
    #------------------------
    # The packages listed by 'jupyter-serverextension list' come from
    # what is specified in ./config/jupyter_notebook_config.json.
    # Yes, as confusing as it may be, it does appear that 'server extensions'
    # are specified in jupyter_notebook_config, not jupyter_server_config.
    #
    if [ -h "${shareDirectoryImpure}/config/jupyter_notebook_config.json" ]; then
      # if it's a symlink, just delete it
      rm "${shareDirectoryImpure}/config/jupyter_notebook_config.json"
    elif [ -f "${shareDirectoryImpure}/config/jupyter_notebook_config.json" ]; then
      echo "Replacing ${shareDirectoryImpure}/config/jupyter_notebook_config.json" >&2
      chmod +w "${shareDirectoryImpure}/config/jupyter_notebook_config.json"
      mv "${shareDirectoryImpure}/config/jupyter_notebook_config.json" "${shareDirectoryImpure}/config/jupyter_notebook_config.json.old"
    fi
    ln -s "${myspecs}/jupyter_notebook_config.json" "${shareDirectoryImpure}/config/jupyter_notebook_config.json"

    #-------------------
    # widgetsnbextension
    #-------------------
    # Not completely sure why this is needed, but without it, things didn't work.
    mkdir -p "${shareDirectoryImpure}/config/nbconfig/notebook.d"
    if [ -h "${shareDirectoryImpure}/config/nbconfig/notebook.d/widgetsnbextension.json" ]; then
      # if it's a symlink, just delete it
      rm "${shareDirectoryImpure}/config/nbconfig/notebook.d/widgetsnbextension.json"
    elif [ -f "${shareDirectoryImpure}/config/nbconfig/notebook.d/widgetsnbextension.json" ]; then
      echo "Replacing ${shareDirectoryImpure}/config/nbconfig/notebook.d/widgetsnbextension.json" >&2
      chmod +w "${shareDirectoryImpure}/config/nbconfig/notebook.d/widgetsnbextension.json"
      mv "${shareDirectoryImpure}/config/nbconfig/notebook.d/widgetsnbextension.json" "${shareDirectoryImpure}/config/nbconfig/notebook.d/widgetsnbextension.json.old"
    fi
    ln -s "${myspecs}/widgetsnbextension.json" "${shareDirectoryImpure}/config/nbconfig/notebook.d/widgetsnbextension.json"

    ##################################
    # prebuilt lab extensions
    # symlink dirs into shared-jupyter
    ##################################

    rm -rf "${shareDirectoryImpure}/labextensions"
    mkdir -p "${shareDirectoryImpure}/labextensions"

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
    ln -s "${pkgs.python3Packages.jupyterlab_hide_code}/share/jupyter/labextensions/jupyterlab-hide-code" "${shareDirectoryImpure}/labextensions/jupyterlab-hide-code"

    # @axlair/jupyterlab_vim
    mkdir -p "${shareDirectoryImpure}/labextensions/@axlair"
    ln -s "${pkgs.python3Packages.jupyterlab_vim}/lib/${pkgs.python3.libPrefix}/site-packages/jupyterlab_vim/labextension" "${shareDirectoryImpure}/labextensions/@axlair/jupyterlab_vim"

    # jupyterlab-vimrc
    ln -s "${pkgs.python3Packages.jupyterlab-vimrc}/lib/${pkgs.python3.libPrefix}/site-packages/jupyterlab-vimrc" "${shareDirectoryImpure}/labextensions/jupyterlab-vimrc"

    # @krassowski/jupyterlab-lsp
    mkdir -p "${shareDirectoryImpure}/labextensions/@krassowski"
    ln -s "${pkgs.python3Packages.jupyterlab-lsp}/share/jupyter/labextensions/@krassowski/jupyterlab-lsp" "${shareDirectoryImpure}/labextensions/@krassowski/jupyterlab-lsp"

    # @ryantam626/jupyterlab_code_formatter
    mkdir -p "${shareDirectoryImpure}/labextensions/@ryantam626"
    ln -s "${pkgs.python3Packages.jupyterlab_code_formatter}/share/jupyter/labextensions/@ryantam626/jupyterlab_code_formatter" "${shareDirectoryImpure}/labextensions/@ryantam626/jupyterlab_code_formatter"

    # jupyterlab-drawio
    ln -s "${pkgs.python3Packages.jupyterlab-drawio}/lib/${pkgs.python3.libPrefix}/site-packages/jupyterlab-drawio/labextension" "${shareDirectoryImpure}/labextensions/jupyterlab-drawio"

    # @aquirdturtle/collapsible_headings
    mkdir -p "${shareDirectoryImpure}/labextensions/@aquirdturtle"
    ln -s "${pkgs.python3Packages.aquirdturtle_collapsible_headings}/share/jupyter/labextensions/@aquirdturtle/collapsible_headings" "${shareDirectoryImpure}/labextensions/@aquirdturtle/collapsible_headings"

    # jupyterlab-system-monitor depends on jupyterlab-topbar and jupyter-resource-usage

    # jupyterlab-topbar
    ln -s "${pkgs.python3Packages.jupyterlab-topbar}/lib/${pkgs.python3.libPrefix}/site-packages/jupyterlab-topbar/labextension" "${shareDirectoryImpure}/labextensions/jupyterlab-topbar-extension"

    # jupyter-resource-usage
    mkdir -p "${shareDirectoryImpure}/labextensions/@jupyter-server"
    ln -s "${pkgs.python3Packages.jupyter-resource-usage}/share/jupyter/labextensions/@jupyter-server/resource-usage" "${shareDirectoryImpure}/labextensions/@jupyter-server/resource-usage"

    # jupyterlab-system-monitor
    ln -s "${pkgs.python3Packages.jupyterlab-system-monitor}/lib/${pkgs.python3.libPrefix}/site-packages/jupyterlab-system-monitor/labextension" "${shareDirectoryImpure}/labextensions/jupyterlab-system-monitor"


    # @arbennett/base16-gruvbox-dark
    # this is a demo of how I took a source lab extension from NPM and
    # prebuilt it in mynixpkgs to be distributed as a Nix package.
    mkdir -p "${shareDirectoryImpure}/labextensions/@arbennett"
    ln -s "${pkgs.base16-gruvbox-dark-labextension}/" "${shareDirectoryImpure}/labextensions/@arbennett/base16-gruvbox-dark"

    ####################################
    # JupyterLab + source lab extensions
    ####################################

    # A source lab extension is an uncompiled JS package (e.g., from NPM)
    # To install one, we compile it together with JupyterLab, producing
    # a built version of JupyterLab that incorporates the lab extension.
    #
    # More info:
    # https://jupyterlab.readthedocs.io/en/stable/extension/extension_dev.html#developer-extensions

    if [ ! -d "${shareDirectoryImpure}/lab/static" ]; then
      # Don't build JupyterLab unless necessary. It takes a long time.
      # If JupyterLab has already been built and there haven't been any changes
      # to JupyterLab or the source lab extensions, we can safely re-use the
      # previous build.
      #
      # We are using the '${shareDirectoryImpure}/lab/static/' directory as a
      # proxy for indicating whether JupyterLab has been built. If you want to
      # rebuild, delete '${shareDirectoryImpure}/lab' and reload.

      mkdir -p "${shareDirectoryImpure}/lab"
      mkdir -p "${shareDirectoryImpure}/lab/staging"

      #------------------------
      # build jupyter lab alone
      #------------------------

      # Note: we pipe stdout to stderr because otherwise $(cat "$\{dump\}")
      # would contain something that should not be evaluated.
      # Look at 'eval $(cat "$\{dump\}")' in ./.envrc file.

      chmod -R +w "${shareDirectoryImpure}/lab/staging/"
      jupyter lab build >&2

      #--------------------------
      # add source lab extensions
      #--------------------------
      # Specifying --no-build so that we can just build once afterward

      # https://github.com/arbennett/jupyterlab-themes

      # Note: we prebuilt this one, so commenting it out here
      #chmod -R +w "${shareDirectoryImpure}/lab/staging/"
      #jupyter labextension install --no-build @arbennett/base16-gruvbox-dark >&2

      # Note: we could prebuild this one too, but for now, I left it here as a
      # demo of installing a source lab extension.
      chmod -R +w "${shareDirectoryImpure}/lab/staging/"
      jupyter labextension install --no-build @arbennett/base16-gruvbox-light >&2

      #-------------------------------------------
      # build jupyter lab w/ source lab extensions
      #-------------------------------------------

      # It would be nice to be able to just build once here at the end, but the
      # build process appears to fail unless I build once for jupyter lab alone
      # then again after adding source lab extensions.

      chmod -R +w "${shareDirectoryImpure}/lab/staging/"
      jupyter lab build >&2

      #chmod -R -w "${shareDirectoryImpure}/lab/staging/"
      # TODO: can I delete the staging directory:
      chmod -R +w "${shareDirectoryImpure}/lab/staging/"
      rm -rf "${shareDirectoryImpure}/lab/staging/"
    else
      echo "Skipping build of JupyterLab and source extensions" >&2
    fi
    '';
  })
