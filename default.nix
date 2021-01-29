with import <nixpkgs> { overlays = [ (import ./python-overlay.nix) ]; };
with pkgs.lib.strings;
let
  #nixos = import <nixos> {};
  # This property is just for jupyter server extensions, but it is
  # OK if the server extension includes a lab extension.
  serverextensions = p: with p; [
    jupytext
    # look into getting jupyterlab-lsp working:
    # https://github.com/krassowski/jupyterlab-lsp
  ];

  mynixpkgs = import (fetchFromGitHub {
    owner = "ariutta";
    repo = "mynixpkgs";
    rev = "aca57c0";
    sha256 = "1ab3izpdfiylzdxq1hpgljbcmdvdwnch8mxcd6ybx4yz8hlp8gm0";
  });

  # TODO: specify a lab extensions property

  jupyter = import (

#    # for dev, clone a jupyterWith fork as a sibling of demo directory
#    ../jupyterWith/default.nix

    # for "prod"
    builtins.fetchGit {
      url = https://github.com/ariutta/jupyterWith;
      ref = "proposals";
    }

  ) {
    # this corresponds to notebook_dir (impure)
    directory = toString ./.;
    labextensions = [
      "jupyterlab_vim"

      # TODO: this may have been needed for bokeh. Can I remove it?
      "@jupyter-widgets/jupyterlab-manager"

    ];
    serverextensions = serverextensions;
    overlays = [ (import ./python-overlay.nix) ];
  };

  #########################
  # R
  #########################

  myRPackages = p: with p; [
    pacman
    dplyr
    ggplot2
    knitr
    purrr
    readr
    stringr
    tidyr
  ];

  #myR = [ nixos.R ] ++ (myRPackages pkgs.rPackages);
  myR = [ R ] ++ (myRPackages pkgs.rPackages);

  juniper = jupyter.kernels.juniperWith {
    # Identifier that will appear on the Jupyter interface.
    name = "JuniperKernel";
    # Libraries (R packages) to be available to the kernel.
    packages = myRPackages;
    # Optional definition of `rPackages` to be used.
    # Useful for overlaying packages.
    # TODO: why not just do this in overlays above?
    #rPackages = pkgs.rPackages;
  };

  #########################
  # Python
  #########################

  myPythonPackages = (p: (with p; [
    numpy
    pandas

    # TODO: the following are not serverextensions, but they ARE specifically
    # intended for augmenting jupyter. Where should we specify them?

    # TODO: compare nb_black with https://github.com/ryantam626/jupyterlab_code_formatter
    nb_black

    beautifulsoup4
    soupsieve

    nbconvert
    seaborn

    requests
    requests-cache

    #google_api_core
    #google_cloud_core
    #google-cloud-sdk
    #google_cloud_testutils
    #google_cloud_automl
    #google_cloud_storage

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
  ]) ++
  # TODO: it would be nice not have to specify serverextensions here, but the
  # current jupyterLab code needs it to be specified both here and above.
  (serverextensions p));

  myPython = pkgs.python3.withPackages(myPythonPackages);

  iPythonWithPackages = jupyter.kernels.iPythonWith {
    name = "IPythonKernel";

    # TODO: I shouldn't need to set this if I'm using overlays, right?
    #python3 = pkgs.python3Packages;

    packages = myPythonPackages;
  };

  jupyterEnvironment =
    jupyter.jupyterlabWith {
      kernels = [ iPythonWithPackages juniper ];

      extraPackages = p: [
        # needed by jupyterlab-launch
        p.ps
        p.lsof

        imagemagick

        # optionals below
        myR

        # needed to make server extensions work
        myPython

        # TODO: do we still need these for lab extensions?
        nodejs
        yarn

        # for nbconvert
        pandoc
        # see https://github.com/jupyter/nbconvert/issues/808
        #tectonic
        # more info: https://nixos.wiki/wiki/TexLive
        texlive.combined.scheme-full
        mynixpkgs.jupyterlab-connect

        # to run AutoML Vision
        google-cloud-sdk

        exiftool

        # to get perceptual hash values of images
        # p.phash
        p.blockhash
      ];
    };
in
  jupyterEnvironment.env.overrideAttrs (oldAttrs: {
    shellHook = oldAttrs.shellHook + ''
    . "${mynixpkgs.jupyterlab-connect}"/share/bash-completion/completions/jupyterlab-connect.bash
    '';
  })
