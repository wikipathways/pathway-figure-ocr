with builtins;

let
  repoDir = toString ./.;

  # If desired, notebookDir can be the same as repoDir
  #notebookDir = repoDir;
  # or it can be a different directory:
  notebookDir = "${repoDir}/notebooks";

  # for local settings, workspaces, etc.
  # TODO: what should be mutable? when should we use ~/.jupyter?
  mutableJupyterDir = "${repoDir}/.share/jupyter";

  # Path to the JupyterWith folder.
  jupyterWithPath = builtins.fetchGit {
    url = https://github.com/tweag/jupyterWith;
    rev = "35eb565c6d00f3c61ef5e74e7e41870cfa3926f7";
  };

  # Path to the poetry2nix folder.
  poetry2nixPath = builtins.fetchGit {
    url = https://github.com/nix-community/poetry2nix;
    rev = "e72ff71c3cc8bbc708dbc13941888eb08a65f651";
  };

  #############
  # My overlays
  #############

  # for dev
  #myoverlay = import ../mynixpkgs/overlay.nix;

  # for prod
  myoverlay = import (builtins.fetchGit {
    url = https://github.com/ariutta/mynixpkgs;
    rev = "ebd930f4d67ff658084281a9a71c6400ac2b912a";
    ref = "main";
  });

  # Importing overlays
  overlays = [
    # makes poetry2nix available
    (import "${poetry2nixPath}/overlay.nix")
    myoverlay
    # jupyterWith overlays
    # Only necessary for Haskell kernel
    (import "${jupyterWithPath}/nix/haskell-overlay.nix")
    # Necessary for Jupyter
    (import "${jupyterWithPath}/nix/python-overlay.nix")
    (import "${jupyterWithPath}/nix/overlay.nix")
  ];

  # Your Nixpkgs snapshot, with JupyterWith packages.
  pkgs = import <nixpkgs> { inherit overlays; config.allowUnfree = true; };

  # 'jupyter-kernelspec list' makes everything lowercase and joins the
  # internal kernel name with this descriptor. Example for descriptor 'mypkgs':
  #   ipython_mypkgs
  #   ir_mypkgs
  #
  # In the JupyterLab GUI, we see the language name joined to the descriptor
  # with a dash. Example for descriptor 'mypkgs':
  #   Python3 - mypkgs
  #   R - mypkgs
  kernel_descriptor = "mypkgs";

  #########################
  # R
  #########################

  # this is a function that accepts an input like pkgs.rPackages
  # It takes that input and selects a subset of packages from
  # the input collection.
  # TODO: how/where should we specify R itself as a dependency?
  selectedRPackagesFn = p: with p; [
    # R itself
    pkgs.R

    # R libraries
    feather
    knitr
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

    conflicted
    processx
    RSelenium
    rvest
    xml2

    #########################
    # For Jupyter/JupyterLab
    #########################

    # I also have an extension for LSP capabilities. To make it work with R,
    # I use the R pkg 'languageserver'.
    languageserver

    # I have installed an extension that formats code on save. I think it's a
    # server extension. To format R code, the formatter appears to rely on the
    # Python library 'rpy2' as well as the R pkg 'formatR'.

    # TODO: Is this always working correctly? I think I've noticed cases where
    # I hit save, the formatter changes the code as I see it in the notebook,
    # and the little circle in Jupyterlab changes to indicates it's saved.
    # But if I close and re-open the file, the code isn't formatted.
    #
    # formatR on Nixpkgs unstable is currently v1.7.
    # I want at least 1.9 so I get pipe formatted correctly:
    # https://yihui.org/formatr/#the-pipe-operator
    #formatR

    ## an alternative formatter:
    styler
    prettycode # seems to be needed by styler
  ];

  allRPackages = pkgs.rPackages;

  # the content above is a function.
  # below, we get a list
  # TODO: Is this actually an R env, similar to the Py env we get from Nix?
  #       Or is it just a list containing R itself and some packages?
  myREnv = (selectedRPackagesFn allRPackages);

  irkernel = jupyter.kernels.iRWith {
    # Identifier that will appear on the Jupyter interface.
    name = kernel_descriptor;
    # Libraries to be available to the kernel.
    # accepts a function like p: with p; [ p.ggplot2 ]
    packages = selectedRPackagesFn;
    # Optional definition of `rPackages` to be used.
    # Useful for overlaying packages.
    rPackages = allRPackages;
  };

  #########################
  # Python
  #########################

  poetry2nixOutput = pkgs.callPackage ./xpm2nix/python-modules/python-with-pkgs.nix {
    inherit pkgs;
  };
  pythonEnv = poetry2nixOutput.poetryEnv;
  # TODO: try to simplify the export from python-with-pkgs.nix
  # Ideally, I could do something like this:
  #   with (poetry2nixOutput = pkgs.callPackage ./xpm2nix/python-modules/python-with-pkgs.nix {}):
  # making these variables available: { python, poetryPackages, pyProject, poetryLock }
  # But right now, pythonEnv as mkPoetryPackages.python gives an error for rpy2,
  # but pythonEnv as mkPoetryEnv.poetryEnv is fine.
  # TODO: why does the following gives an error about rpy2 not being available?
  #pythonEnv = poetry2nixOutput.poetryPackages.python;

  # pyProjectDepNames and poetryLockDepNames below are not identical.
  # pyProjectDepNames is top-level only, but poetryLockDepNames includes deps of deps.

  # the dep names specified in pyproject.toml
  # note: this includes 'python' as a dependency.
  pyProjectDepNames = pkgs.lib.attrNames poetry2nixOutput.poetryPackages.pyProject.tool.poetry.dependencies;

  # the deps as translated by poetry from pyproject.toml to poetry.lock
  poetryLockDeps = poetry2nixOutput.poetryPackages.poetryLock.package;
  # just the names
  poetryLockDepNames = pkgs.lib.lists.map (x: x.name) poetryLockDeps;
  # the derivations
  poetryLockDepDrvs = pkgs.lib.lists.map (x: pkgs.lib.attrsets.getAttr(x) pythonEnv.pkgs) poetryLockDepNames;

  # TODO: figure out how to handle jupyterlab extensions that are dependencies
  # of the ones we specify, e.g., we specify jupyterlab-system-monitor, and it
  # depends on on jupyterlab-topbar-extension, so that needs to be in
  # .share/jupyter/labextensions too. For now, I just manually added those to
  # pyproject.toml, but I should have to. I tried the second line below, but
  # that fails when I evaluate appnope, which is just for macOS.
  shareJupyterPyDrvs = builtins.filter (x: builtins.pathExists "${x}/share/jupyter") poetry2nixOutput.poetryPackages.poetryPackages;
  #shareJupyterPyDrvs = builtins.filter (x: (builtins.tryEval (builtins.pathExists "${x}/share/jupyter"))) poetryLockDepDrvs;
  shareJupyterPyDepNames = pkgs.lib.lists.map (x: x.pname) shareJupyterPyDrvs;

  # the packages in both pyProjectDepNames poetryLockDepNames
  # TODO: this can fail if I specify python_magic in pyproject.toml,
  # but the pname is python-magic.
  intersectedDepNames = (pkgs.lib.lists.intersectLists pyProjectDepNames poetryLockDepNames);

  nonJupyterPyDepNames = pkgs.lib.lists.subtractLists shareJupyterPyDepNames intersectedDepNames;
  nonJupyterPyDeps = pkgs.lib.lists.map (x: pkgs.lib.attrsets.getAttr(x) pythonEnv.pkgs) nonJupyterPyDepNames;

  pyProjectDepNamesNotLock = pkgs.lib.lists.subtractLists poetryLockDepNames pyProjectDepNames;
  poetryLockNotPyProj = pkgs.lib.lists.subtractLists pyProjectDepNames poetryLockDepNames;

  jupyter = pkgs.jupyterWith;

  iPython = jupyter.kernels.iPythonWith {
    name = kernel_descriptor;

    # if we don't specify this, jupyter will use the default of pkgs.python3
    # rather than the python environment we created with poetry.
    python3 = pythonEnv;

    # Python libraries to be available to the kernel.
    # 'p: with p;' means use the packages for 'iPython.python3' (specified above)
    #              so we can just list a package name and the prefix
    #              'python3.pkgs.' will be understood.
    packages = p: with p; nonJupyterPyDeps;
  };

  ######################
  # extensions & configs
  ######################

  npmLabextensions = pkgs.callPackage ./xpm2nix/node-packages/labextensions.nix {
    jq=pkgs.jq;
    jupyter=pythonEnv.pkgs.jupyter;
    jupyterlab=pythonEnv.pkgs.jupyterlab;
    nodejs=pkgs.nodejs;
    setuptools=pythonEnv.pkgs.setuptools;
  };

  shareSrc = ./share-src;
  shareJupyter = pkgs.symlinkJoin {
    name = "my-share-jupyter";

    # we use this directory of symlinks in the jupyterWith shellHook
    paths =
      (pkgs.lib.lists.map (x: "${x}/share/jupyter") (
        shareJupyterPyDrvs
      ))
      ++ [npmLabextensions shareSrc];

    # We also add config files from shareSrc
    # I think we need to specify them like this because Jupyter needs the config
    # directory to be writable, so symlinks to the Nix store won't work.
    postBuild = ''
      rm "$out/config/jupyter_server_config.json"
      substitute "${shareSrc}/config/jupyter_server_config.json" "$out/config/jupyter_server_config.json" --subst-var-by notebookDir "${notebookDir}"

      rm "$out/config/jupyter_notebook_config.json"
      substitute "${shareSrc}/config/jupyter_notebook_config.json" "$out/config/jupyter_notebook_config.json" --subst-var-by notebookDir "${notebookDir}"
    '';
  };

  ####################
  # jupyterEnvironment
  ####################

  jupyterEnvironment =
    jupyter.jupyterlabWith {

      # JupyterLab Application Directory
      # <sys-prefix>/share/jupyter/lab
      # https://jupyterlab.readthedocs.io/en/stable/user/directories.html#jupyterlab-application-directory
      directory = "${shareJupyter}/lab";

      kernels = [ iPython irkernel ];

      extraPackages = p: [
        p.dos2unix

        # general image library
        p.imagemagick
        # vector image library
        p.inkscape

        # to run AutoML Vision
        p.google-cloud-sdk

        p.exiftool

        # to get perceptual hash values of images
        # p.phash
        p.blockhash
      ]
      #------------
      # below are extraPackages required by Jupyter/JupyterLab
      #------------
      # TODO: figure out a cleaner way of doing this
      ++ [
        # Some pythonEnv packages are for augmenting Jupyter, while others are
        # just regular Python packages, unrelated to Jupyter.
        #
        # TODO: it appears some of the packages for augmenting Jupyter need to
        # be specified here. if I comment out both pythonEnv and
        # pythonEnv.pkgs.jupyterlab-code-formatter, then
        # jupyterlab-code-formatter complains it can't find its server extension,
        # and I get this error about rpy2:
        #
        #   Error while finding module specification for 'rpy2.situation'
        #   (ModuleNotFoundError: No module named 'rpy2')
        # 
        # But if I enable either of the two lines below, I get no errors;
        #pythonEnv
        pythonEnv.pkgs.jupyterlab-code-formatter

        # Likewise, if pythonEnv isn't enabled above, I need to explicitly
        # specify the Python/PyPI extensions below for them to work:

        # At one point, jupyterlab-lsp needed to be specified here in order for
        # the LSP for R to work, but that might not be the case anymore
        # possibly because I now make sure those are installed as extensions.
        #pythonEnv.pkgs.jupyter-lsp
        #pythonEnv.pkgs.jupyterlab-lsp
      ]
      # TODO: is the code below the best way to specify the R deps?
      ++ myREnv
      ++ [ p.selenium-server-standalone p.geckodriver ];

      #----------------
      # extraInputsFrom
      #----------------

      # Bring all inputs from a package in scope.
      # This is required to make deps available when needed, e.g.,
      # to make pandoc available to nbconvert.
      extraInputsFrom = p: [ p.pkgs.pandoc p.pkgs.texlive.combined.scheme-full ];

      #-----------------
      # extraJupyterPath
      #-----------------

      # Make paths available to Jupyter itself, generally for server extensions
      # TODO: Is what I have here OK (w/ everything included in pythonEnv), or
      # should I limit this to server extensions?
      extraJupyterPath = pkgs:
        concatStringsSep ":" [
          "${pythonEnv}/${pythonEnv.sitePackages}"
        ];
    };
in
  jupyterEnvironment.env.overrideAttrs (oldAttrs: {
    shellHook = oldAttrs.shellHook + ''
      # this is needed in order that tools like curl and git can work with SSL
      # or maybe even just  for direnv?
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
      # maybe when using nix-shell?
      #export SSL_CERT_FILE=${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt

      # set SOURCE_DATE_EPOCH so that we can use python wheels
      SOURCE_DATE_EPOCH=$(date +%s)

      ######################
      # Jupyter + JupyterLab
      ######################

      #---------
      # set dirs
      #---------

      mkdir -p "${mutableJupyterDir}"

      # The following directories are OK with being immutable:

      export JUPYTER_CONFIG_DIR="${shareJupyter}/config"
      export JUPYTERLAB_DIR="${shareJupyter}/lab"

      # The following directories are themselves OK with being immutable, but I
      # only know how to point Jupyter to them via JUPYTER_DATA_DIR, which must
      # be immutable. So I add symlinks pointing to the latest immutable
      # directories from within the mutable JUPYTER_DATA_DIR.

      if [ -e "${mutableJupyterDir}/labextensions" ]; then
        rm "${mutableJupyterDir}/labextensions"
      fi
      ln -s "${shareJupyter}/labextensions" "${mutableJupyterDir}/labextensions"

      if [ -e "${mutableJupyterDir}/nbextensions" ]; then
        rm "${mutableJupyterDir}/nbextensions"
      fi
      ln -s "${shareJupyter}/nbextensions" "${mutableJupyterDir}/nbextensions"

      if [ -e "${mutableJupyterDir}/nbconvert" ]; then
        rm "${mutableJupyterDir}/nbconvert"
      fi
      ln -s "${shareJupyter}/nbconvert" "${mutableJupyterDir}/nbconvert"

      # The following directories must be mutable:

      export JUPYTER_DATA_DIR="${mutableJupyterDir}"
      mkdir -p "$JUPYTER_DATA_DIR"

      # TODO: Can I automatically generate the info contained in this file?
      # ./share-src/config/nbconfig/notebook.d/load_nbextensions.json
      #
      # It seems I could get that info by looking at the contents
      # of ${shareJupyter}/nbextensions

      if [ -e "${mutableJupyterDir}/config/nbconfig" ]; then
        rm -rf "${mutableJupyterDir}/config/nbconfig"
      fi
      mkdir -p "${mutableJupyterDir}/config"
      ln -s "${shareJupyter}/config/nbconfig" "${mutableJupyterDir}/config/nbconfig"

      # if we don't want to allow the user to specify settings, this could be made immutable
      export JUPYTERLAB_SETTINGS_DIR="${mutableJupyterDir}/config/lab/user-settings/"
      mkdir -p "$JUPYTERLAB_SETTINGS_DIR"

      export JUPYTERLAB_WORKSPACES_DIR="${mutableJupyterDir}/config/lab/workspaces/"
      mkdir -p "$JUPYTERLAB_WORKSPACES_DIR"

      export JUPYTER_RUNTIME_DIR="${mutableJupyterDir}/runtime"
      mkdir -p "$JUPYTER_RUNTIME_DIR"

      #------------
      # other stuff
      #------------

      # This line is from the nixpkgs generic R package builder:
      #export LD_LIBRARY_PATH="$LD_LIBRARY_PATH''${LD_LIBRARY_PATH:+:}${pkgs.R}/lib/R/lib"

      # I modified it a bit to work with rpy2:
      export LD_LIBRARY_PATH="$LD_LIBRARY_PATH''${LD_LIBRARY_PATH:+:}$(python -m rpy2.situation LD_LIBRARY_PATH)"

      # Without that line above, I get the following error when I launch JupyterLab:
      #
      # Jupyterlab Code Formatter Error
      # Unable to find server plugin version, this should be impossible,open a GitHub issue if you cannot figure this issue out yourself.
      #
      # TODO: what is this code doing and how should it be configured?

      # Message from mybinder when launching:
      #
      # Installation finished!  To ensure that the necessary environment
      # variables are set, either log in again, or type
      # 
      #   . /home/jovyan/.nix-profile/etc/profile.d/nix.sh
      # 
      # in your shell.
      #
      # Hence, the code below to make everything work on mybinder:
      if [ -f /home/jovyan/.nix-profile/etc/profile.d/nix.sh ]; then
         . /home/jovyan/.nix-profile/etc/profile.d/nix.sh
      fi
    '';
  })
