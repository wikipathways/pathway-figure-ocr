with builtins;
#4

# TODO: clean up how to specify extensions
#
# Types of extensions:
# --------------------
# Jupyter lab extensions
# Jupyter server extensions
# notebook extensions
# bundler extensions (not sure what this is)
# --------------------
# Python magics (not really extensions)
# --------------------
# CLI dependencies for any of the above

# I also want to be able to run my python both from a notebook
# and also from the command line.

let
  repoDir = toString ./.;
  # If desired, notebookDir can be the same as repoDir
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
    name = kernel_descriptor;
    # Libraries to be available to the kernel.
    packages = myRPackages;
    # Optional definition of `rPackages` to be used.
    # Useful for overlaying packages.
    rPackages = pkgs.rPackages;
  };

  #########################
  # Python
  #########################

  poetry2nixOutput = pkgs.callPackage ./xpm2nix/python-modules/python-with-pkgs.nix {
    inherit pkgs;
  };
  pythonEnv = poetry2nixOutput.poetryEnv;
  # TODO: why does the following gives an error about rpy2 not being available?
  #pythonEnv = poetry2nixOutput.poetryPackages.python;

  # the dep names specified in pyproject.toml
  pyProjectDepNames = pkgs.lib.attrNames poetry2nixOutput.poetryPackages.pyProject.tool.poetry.dependencies;
  # the deps as translated by poetry from pyproject.toml to poetry.lock
  poetryLockDeps = poetry2nixOutput.poetryPackages.poetryLock.package;
  # just the names
  poetryLockDepNames = pkgs.lib.lists.map (x: x.name) poetryLockDeps;

  #pyProjectDeps = pkgs.lib.lists.filter (x: (pkgs.lib.lists.elem x.name intersectedDepNames)) poetryLockDeps;

  #jupyterDepNames = poetry2nixOutput.poetryPackages.poetryLock.extras.jupyter;
  #jupyterDeps = pkgs.lib.lists.filter (x: (pkgs.lib.lists.elem x.name jupyterDepNames)) poetryLockDeps;
  jupyterDeps = builtins.filter (x: builtins.pathExists "${x}/share/jupyter") poetry2nixOutput.poetryPackages.poetryPackages;
  jupyterDepNames = pkgs.lib.lists.map (x: x.name) jupyterDeps;

  intersectedDepNames = (pkgs.lib.lists.intersectLists pyProjectDepNames poetryLockDepNames);

  nonJupyterDepNames = pkgs.lib.lists.subtractLists jupyterDepNames intersectedDepNames;
  nonJupyterDeps = pkgs.lib.lists.map (x: pkgs.lib.attrsets.getAttr(x) pythonEnv.pkgs) nonJupyterDepNames;

#  boo = 1
#  boo = 1
#
#  poetry2nixOutput = pkgs.callPackage ./xpm2nix/python-modules/python-with-pkgs.nix {
#    inherit pkgs;
#    pythonOlder = pkgs.python3.pythonOlder;
#  }
#
#  # the dep names specified in pyproject.toml
#  pyProjectDepNames = pkgs.lib.attrNames poetry2nixOutput.poetryPackages.pyProject.tool.poetry.dependencies
#  # the deps as translated by poetry from pyproject.toml to poetry.lock
#  poetryLockDeps = poetry2nixOutput.poetryPackages.poetryLock.package
#  # just the names
#  poetryLockDepNames = pkgs.lib.lists.map (x: x.name) poetryLockDeps
#
#  pyProjectDepNames = pkgs.lib.attrNames poetry2nixOutput.poetryPackages.pyProject.tool.poetry.dependencies
#
#  intersectedDepNames = (pkgs.lib.lists.intersectLists pyProjectDepNames poetryLockDepNames)
#
#  (pkgs.lib.lists.map (x: pkgs.lib.lists.elem x.name intersectedDepNames))
#
#
#    (pkgs.lib.lists.map (x: x) (
#      pkgs.lib.lists.filter (x: ! (
#        (x ? dependencies.jupyter) || (x ? dependencies.jupyterlab) || (x == "python")
#      )) pyProjectDeps
#    ))
#
#
#    (pkgs.lib.lists.map (x: x) (
#      pkgs.lib.lists.filter (x: ! (
#        (x ? dependencies.jupyter) || (x ? dependencies.jupyterlab) || (x == "python")
#      )) (pkgs.lib.lists.map (x: pkgs.lib.attrsets.getAttr(x) poetryLockDeps) (pkgs.lib.lists.subtractLists [ "python" "jupyter" "jupyterlab" ] pyProjectDepNames))
#    ))

  # pyProjectDepNames and poetryLockDepNames are not identical.
  # pyProjectDepNames is top-level only, but poetryLockDepNames also includes dependencies.
  #
  # pkgs.lib.lists.subtractLists (pkgs.lib.lists.map (x: x.name)
  #   poetry2nixOutput.poetryPackages.poetryLock.package)
  #   (pkgs.lib.attrNames poetry2nixOutput.poetryPackages.pyProject.tool.poetry.dependencies)

  # TODO: can we auto-fill whatever is needed for the following?
  # iPython.packages
  # jupyterEnvironment.extraPackages
  # jupyterEnvironment.extraJupyterPath
  #
  # Those all seem to need at least some packages from poetry2nixOutput.
  # It would be great to auto-fill them like I'm doing for extensions.
  #
  # Maybe this one could also use something from poetry2nixOutput?
  # jupyterEnvironment.extraInputsFrom

  python3 = pythonEnv;

  jupyter = pkgs.jupyterWith;

  # TODO: take a look at xeus-python
  # https://github.com/jupyter-xeus/xeus-python#what-are-the-advantages-of-using-xeus-python-over-ipykernel-ipython-kernel
  # It supports the jupyterlab debugger. But it's not packaged for nixos yet.

  iPython = jupyter.kernels.iPythonWith {
    name = kernel_descriptor;

    # if we don't specify this, jupyter will use the default of pkgs.python3
    # rather than the python environment we created with poetry.
    python3 = pythonEnv;

    # Python libraries to be available to the kernel.
    # 'p: with p;' tells this to work w/ the packages in whatever is specified
    # as python3 above. It adds 'python3.pkgs.' as a prefix for each item.
#    packages = p: with p; (pkgs.lib.lists.map (x: pkgs.lib.attrsets.getAttr(x) pythonEnv.pkgs) (
#      pkgs.lib.lists.filter (x: ! (
#        (x ? dependencies.jupyter) || (x ? dependencies.jupyterlab) || (x == "python")
#      )) pyProjectDepNames 
#    ));

    packages = p: with p; nonJupyterDeps;

#    # Python libraries to be available to the kernel.
#    # 'p: with p;' tells this to work w/ the packages in whatever is specified
#    # as python3 above. It adds 'python3.pkgs.' as a prefix for each item.
#    packages = p: with p; [
#      # TODO: which packages exactly are supposed to be in here?
#      # It appears extensions like jupyter-code-formatter, jupytext and nbconvert
#      # are all working without being specified here.
#      # Is this supposed to be for non-Jupyter/JupyterLab packages?
#      # Could I just add to this section every package in pyproject.toml that
#      # doesn't depend on jupyter or jupyterlab?
#
#      lxml
#
#      skosmos-client
#
#      # the following isn't automatically working w/ poetry2nix (maybe disable tests?)
#      #wikidata2df
#
#      ############
#      # requests+
#      ############
#      requests
#      requests-cache
#
#      ############
#      # Pandas+
#      ############
#      numpy
#      pandas
#      pyarrow # needed for pd.read_feather()
#
#      scipy
#
#      # the following two aren't automatically working w/ poetry2nix
#      #seaborn
#      #matplotlib
#
#      ########
#      # rpy2
#      ########
#      rpy2
#      # tzlocal is needed to make rpy2 work
#      tzlocal
#      # TODO: is simplegeneric also needed?
#      simplegeneric
#
#      ##################
#      # Parse messy HTML
#      ##################
#      beautifulsoup4
#      soupsieve
#
#      ########
#      # Text
#      ########
#
#      # for characters that look like each other
#      confusable-homoglyphs
#      # the following isn't automatically working w/ poetry2nix
#      #homoglyphs
#
#      # fix encodings
#      ftfy
#
#      pyahocorasick
#      # the following isn't automatically working w/ poetry2nix (Cython issue)
#      #spacy
#      unidecode
#
#      ########
#      # Images
#      ########
#
#      # Python interface to the libmagic file type identification library
#      # This has nothing to do w/ Jupyter magics or ImageMagick.
#      python_magic
#
#      # python bindings for imagemagick
#      Wand
#
#      # Python Imaging Library
#      pillow
#
#      ########
#      # Google
#      ########
#
#      google-api-core
#      #google_cloud_core
#      #google-cloud-sdk
#      #google_cloud_testutils
#      #google_cloud_automl
#      #google_cloud_storage
#    ];
  };

  ######################
  # Extensions & configs
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

#    paths = (pkgs.lib.lists.map (x: "${x}/share/jupyter") (
#      (pkgs.lib.lists.map (x: pkgs.lib.attrsets.getAttr(x) pythonEnv.pkgs) (
#        pkgs.lib.lists.filter (x: x ? dependencies.jupyterlab) pyProjectDepNames
#      )) ++ (
#        with pythonEnv.pkgs; [jupyterlab jupyterlab-code-formatter jupytext widgetsnbextension jupyter-resource-usage nbconvert]
#      ))
#    ) ++ [npmLabextensions shareSrc];

#    paths = (pkgs.lib.lists.map (x: "${x}/share/jupyter") (
#      (pkgs.lib.lists.map (x: pkgs.lib.attrsets.getAttr(x) pythonEnv.pkgs) (
#        pkgs.lib.lists.filter (x: x ? dependencies.jupyterlab) jupyterDepNames
#      )) ++ (
#        with pythonEnv.pkgs; [jupyterlab jupyterlab-code-formatter jupytext widgetsnbextension jupyter-resource-usage nbconvert]
#      ))
#    ) ++ [npmLabextensions shareSrc];

#    paths = (pkgs.lib.lists.map (x: "${x}/share/jupyter") (
#        (pkgs.lib.lists.map (x: pkgs.lib.attrsets.getAttr(x.name) pythonEnv.pkgs) (
#          pkgs.lib.lists.filter (x: (x ? dependencies.jupyter) || (x ? dependencies.jupyter-core) || (x ? dependencies.notebook) || (x ? dependencies.jupyterlab)) jupyterDeps
#        ))
##        ++ (pkgs.lib.lists.map (x: pkgs.lib.attrsets.getAttr(x) pythonEnv.pkgs) (
##          ["jupyterlab" "jupyterlab-code-formatter" "jupytext" "widgetsnbextension" "jupyter-resource-usage"]
##        ))
#      ))
##        ++ (
##          with pythonEnv.pkgs; [jupyterlab jupyterlab-code-formatter jupytext widgetsnbextension jupyter-resource-usage nbconvert]
##        ))
#      ++ [npmLabextensions shareSrc];

#    paths = (pkgs.lib.lists.map (x: "${x}/share/jupyter") (
#      jupyterDepNames)
#    ) ++ [npmLabextensions shareSrc];

    paths =
      (pkgs.lib.lists.map (x: "${x}/share/jupyter") (
        builtins.filter (x: builtins.pathExists "${x}/share/jupyter") poetry2nixOutput.poetryPackages.poetryPackages
      ))
      ++ [npmLabextensions shareSrc];

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

      # Add extra packages to the JupyterWith environment
      # TODO: which packages exactly are supposed to be here?
      extraPackages = p: [
        #############
        # Non-Jupyter
        #############

        p.dos2unix
        p.inkscape

        p.imagemagick

        # to run AutoML Vision
        p.google-cloud-sdk

        p.exiftool

        # to get perceptual hash values of images
        # p.phash
        p.blockhash

        ####################
        # For Jupyter
        ####################

        # TODO: is there a way to either add these all automatically, or else
        # specify them somehow in ./xpm2nix/python-modules/?

        # Note: pythonEnv has packages for augmenting Jupyter as well
        # as for other purposes.
        # TODO: should it be specified here?
        # At present, if I comment out both pythonEnv and
        # pythonEnv.pkgs.jupyterlab-code-formatter, then
        # jupyterlab-code-formatter complains it can't find its server extension.
        # 
        # But if I enable either of the two lines below, jupyterlab-code-formatter works.
        pythonEnv
        #pythonEnv.pkgs.jupyterlab-code-formatter

        # Likewise, if pythonEnv isn't enabled above, I need to explicitly
        # specify the Python/PyPI extensions below for them to work:

        # jupyterlab-lsp must be specified here in order for the LSP for R to work.
        #pythonEnv.pkgs.jupyter-lsp
        #pythonEnv.pkgs.jupyterlab-lsp

        # jupytext: ipynb <-> other notebook-ish formats
        #     like py:sphinx, py:hydrogen, py:light and Rmd
        # tests:
        # jupytext notebooks/testthis.ipynb --to py

        #pythonEnv.pkgs.jupytext

        # jupyter-nbconvert : ipynb -> read-only formats like pdf, html, etc.
        # tests:
        # jupyter-nbconvert notebooks/testthis.ipynb --to html
        # jupyter-nbconvert notebooks/testthis.ipynb --to pdf
        # jupyter-nbconvert notebooks/testthis.ipynb --to latex

        # TODO: is this the best way to specify the R deps below?

        p.R
      ] ++ (with pkgs.rPackages; [
        ################################################
        # For server extensions that rely on R or R pkgs
        ################################################
        # TODO: is it possible to specify these via extraJupyterPath or extraInputsFrom?
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

      # Bring all inputs from a package in scope.
      # This is required to make deps available when needed, e.g.,
      # to make pandoc available to nbconvert.
      # TODO: which of the following should I use?
      #extraInputsFrom = p: [ pythonEnv.pkgs.nbconvert ];
      #extraInputsFrom = p: [ p.pythonPackages.nbconvert ];

      # TODO: extraInputsFrom as specified above gives an error when using direnv:
      #
      # ./.envrc:109: Sourcing: command not found
      #
      # This is presumably because the dump.env file
      # ./.direnv/wd-86452ccdf0879f88e537141a4809226d/dump.env
      # is modified when extraInputsFrom has a python package,
      # with the following lines being added:
      #
      # Sourcing python-remove-tests-dir-hook
      # Sourcing python-catch-conflicts-hook.sh
      # Sourcing python-remove-bin-bytecode-hook.sh
      # Sourcing setuptools-build-hook
      # Using setuptoolsBuildPhase
      # Sourcing pip-install-hook
      # Using pipInstallPhase
      # Sourcing python-imports-check-hook.sh
      # Using pythonImportsCheckPhase
      # Sourcing python-namespaces-hook

      # so for now, I'll just manually specify these deps for nbconvert:
      extraInputsFrom = p: [ p.pkgs.pandoc p.pkgs.texlive.combined.scheme-full ];

      # I also tried these, but they didn't work:
      #extraInputsFrom = p: p.pythonPackages.nbconvert.propagatedBuildInputs;
      #extraInputsFrom = p: pythonEnv.pkgs.nbconvert.propagatedBuildInputs;

      # Make paths available to Jupyter itself, generally for server extensions
      # TODO: is what I have here OK (w/ everything included in pythonEnv), or
      # should I just specify server extensions?
      extraJupyterPath = pkgs:
        concatStringsSep ":" [
          "${pythonEnv}/${python3.sitePackages}"
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

      #export R_HOME="${pkgs.R}/lib/R"
      #export R_LIBS_SITE="$R_LIBS_SITE''${R_LIBS_SITE:+:}${pkgs.R}/lib/R/library:${pkgs.rPackages.languageserver}/library:${pkgs.rPackages.xml2}/library:${pkgs.rPackages.R6}/library"
      
      # TODO: this general format came from the nixpkgs generic R package builder.
      # What does it do?
      #export LD_LIBRARY_PATH="$LD_LIBRARY_PATH''${LD_LIBRARY_PATH:+:}${pkgs.R}/lib/R/lib"

      # this doesn't work. it gives this message:
      #   R cannot be found in the PATH and RHOME cannot be found.
      export LD_LIBRARY_PATH="$LD_LIBRARY_PATH''${LD_LIBRARY_PATH:+:}$(python -m rpy2.situation LD_LIBRARY_PATH)"
      #export LD_LIBRARY_PATH="$LD_LIBRARY_PATH''${LD_LIBRARY_PATH:+:}$(python -m rpy2.situation LD_LIBRARY_PATH)"
      # but strangely, this gives a result
      #direnv exec Documents/sandbox/pathway-figure-ocr/ sh -c 'python -m rpy2.situation LD_LIBRARY_PATH'
      # and so does this:
      #direnv exec Documents/sandbox/pathway-figure-ocr/ sh -c 'which R'
      # and this:
      #direnv exec Documents/sandbox/pathway-figure-ocr/ R --version

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
    '';
  })

  # TODO: rename directory variables to match what Jupyter uses.
  # https://jupyter.readthedocs.io/en/latest/use/jupyter-directories.html
  # https://jupyterlab.readthedocs.io/en/stable/user/directories.html#jupyterlab-application-directory
  # https://jupyter-notebook.readthedocs.io/en/stable/config.html
  # https://jupyter-server.readthedocs.io/en/latest/search.html?q=jupyter_server_config.json
  # https://jupyterlab.readthedocs.io/en/stable/user/directories.html

  # TODO: ./.envrc:109: Sourcing: command not found

  # TODO: @krassowski/jupyterlab-lsp:signature settings schema could not be found and was not loaded

  # NOTE: If JUPYTER_DATA_DIR is made immutable, I get the following error:
  # Unexpected error while saving file: Untitled.ipynb HTTP 500: Internal Server Error
  # (Unexpected error while saving file: Untitled.ipynb [Errno 30] Read-only file system: '/nix/store/rjcbrkd1br3d4kckw1m1ppn9ksv6sm0c-my-share-jupyter-0.0.0/notebook_secret')

  # I also got an error when I created an R ipynb file and tried saving it:
  #
  # File Save Error for Untitled1.ipynb
  # Unexpected error while saving file: Untitled1.ipynb HTTP 500: Internal Server Error (Unexpected error while saving file: Untitled1.ipynb attempt to write a readonly database)
  #
  # Possibly because this file changes when we create a new notebook:
  # .share/jupyter/nbsignatures.db

  # To identify which files must be mutable, make all dirs mutable and then:
  #
  # newer .share
  # find .share/ -newermt '2021-04-12 19:00'
  #
  # or
  #
  # find .share/ -newer .share/jupyter/nbextensions/jupytext/jupytext_menu.png

  # .share/jupyter/nbconvert/templates
  # .share/jupyter/notebook_secret
  # .share/jupyter/nbsignatures.db
  # .share/jupyter/runtime/jupyter_cookie_secret
  # .share/jupyter/runtime/jpserver-26238.json
  #
  # R or Python kernel launched:
  # .share/jupyter/runtime/kernel-87d047eb-f646-473a-9f17-fac7fcfe7d75.json
  #
  # .share/jupyter/runtime/jpserver-26238-open.html
  # .share/jupyter/config/lab/user-settings/@jupyterlab/application-extension/sidebar.jupyterlab-settings
  # .share/jupyter/config/lab/workspaces/default-37a8.jupyterlab-workspace

  # TODO: I was getting the following error message:
  # Generating grammar tables from /nix/store/sr8r3k029wvgdbv2zr36wr976dk1lya6-python3-3.8.7-env/lib/python3.8/site-packages/blib2to3/Grammar.txt
  # Writing grammar tables to /home/ariutta/.cache/black/20.8b1/Grammar3.8.7.final.0.pickle
  # Writing failed: [Errno 2] No such file or directory: '/home/ariutta/.cache/black/20.8b1/tmppem8fqj6'

  # I made it go away by manually adding the directory, but shouldn't this be automatic?
  # mkdir -p /home/ariutta/.cache/black/20.8b1/

  # nix-store -q --roots /nix/store/93hc8xfc1krv8ab2wi1z246q415iaaw5-python3.8-rpy2-3.4.1    
  # nix-store -q --referrers /nix/store/93hc8xfc1krv8ab2wi1z246q415iaaw5-python3.8-rpy2-3.4.1    
  # for x in $(ls -1 /nix/store | grep rpy2); do echo ""; echo "/nix/store/$x"; sudo nix-store -q --roots /nix/store/"$x"; done

  # TODO: for code formatting, compare nb_black with jupyterlab-code-formatter.
  # One difference:
  # nb_black is an IPython Magic (%), whereas
  # jupyterlab-code-formatter is a combo lab & server extension.
  # https://github.com/ryantam626/jupyterlab_code_formatter
  #
  # For JupyterLab, call nb_black w/ %load_ext lab_black
  # https://pypi.org/project/nb-black/
  # https://github.com/dnanhkhoa/nb_black
