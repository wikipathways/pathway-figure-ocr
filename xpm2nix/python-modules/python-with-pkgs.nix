{pkgs, poetry2nix, substituteAll, R, lib, stdenv ? pkgs.stdenv}:

with builtins;
let
  overrides = poetry2nix.overrides.withDefaults (self: super: {

    aquirdturtle-collapsible-headings = super.aquirdturtle-collapsible-headings.overridePythonAttrs(oldAttrs: {
      nativeBuildInputs = oldAttrs.nativeBuildInputs ++ [
        super.jupyter-packaging
      ];
    });

    ipython-sql = super.ipython-sql.overridePythonAttrs(oldAttrs: {
      prePatch = (oldAttrs.prePatch or "") + ''
        # In the source repo, there is a file NEWS.rst, but when poetry downloads
        # the source, it doesn't have NEWS.rst. So we generate a dummy version.

        touch NEWS.rst

        # The following alternative also works, but it's probably more brittle:
        #substituteInPlace setup.py --replace "NEWS = open(os.path.join(here, 'NEWS.rst'), encoding='utf-8').read()" 'NEWS = ""'
        # It appears substituteInPlace doesn't support regular expressions,
        # b/c the following doesn't work:
        #substituteInPlace setup.py --replace "^NEWS.+$" 'NEWS = ""'
      '';
    });
#    # TODO: is the following needed?
#    ipython_sql = self.ipython-sql;

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
      preCheck = (oldAttrs.preCheck or "") + ''
        # this is needed for rpy2 to pass its checks
        # it was needed when I created the nixpkg myself. is it still needed here?
        export R_HOME="${R}/lib/R"
      '';
      propagatedBuildInputs = (oldAttrs.propagatedBuildInputs or []) ++ [ R self.jupyterlab self.rpy2 ];
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

    ################################################
    # jupyterlab-vim & jupyterlab-vimrc
    # TODO: Can we use the "normal" build & install
    #       somehow? I got an error when I tried it.
    ################################################

    jupyterlab-vim = super.jupyterlab-vim.overridePythonAttrs(oldAttrs: {
      nativeBuildInputs = oldAttrs.nativeBuildInputs ++ [
        super.jupyter-packaging
      ];

      doCheck = false;

      format = "other";

      buildPhase = ''
        mkdir -p "$out/lib/python3.8/site-packages"
        cp -r ./jupyterlab_vim "$out/lib/python3.8/site-packages/jupyterlab_vim"

        mkdir -p "$out/share/jupyter/labextensions/@axlair"
        cp -r ./jupyterlab_vim/labextension "$out/share/jupyter/labextensions/@axlair/jupyterlab_vim"
        cp ./install.json "$out/share/jupyter/labextensions/@axlair/jupyterlab_vim/install.json"
      '';

      installPhase = ''
        echo "installPhase" 1>&2
      '';
    });

    jupyterlab-vimrc = super.jupyterlab-vimrc.overridePythonAttrs(oldAttrs: {
      nativeBuildInputs = oldAttrs.nativeBuildInputs ++ [
        super.jupyter-packaging
      ];

      doCheck = false;

      format = "other";

      buildPhase = ''
        # diff -r ../binder-nix-demo/jupyterlab-vimrc-0.5.2/jupyterlab-vimrc/static/ .venv/share/jupyter/labextensions/jupyterlab-vimrc/

        mkdir -p "$out/lib/python3.8/site-packages"
        cp -r ./jupyterlab-vimrc/static "$out/lib/python3.8/site-packages/jupyterlab-vimrc"

        mkdir -p "$out/share/jupyter/labextensions"
        cp -r ./jupyterlab-vimrc/static "$out/share/jupyter/labextensions/jupyterlab-vimrc"
      '';

      installPhase = ''
        echo "installPhase" 1>&2
      '';
    });

    jupyterlab-widgets = super.jupyterlab-widgets.overridePythonAttrs(oldAttrs: {
      nativeBuildInputs = oldAttrs.nativeBuildInputs ++ [
        super.jupyter-packaging
      ];
    });

    # jupytext is for ipynb <-> other notebook-ish formats, e.g.:
    #     py:sphinx, py:hydrogen, py:light and Rmd
    #
    # Sample conversion:
    # jupytext notebooks/sandbox.py.ipynb --to py

    jupytext = super.jupytext.overridePythonAttrs(oldAttrs: {
      nativeBuildInputs = oldAttrs.nativeBuildInputs ++ [
        super.jupyter-packaging
      ];
      # TODO: why isn't the labextension in the python package by default?
      #       Also, why do most packages duplicate it in lib and share?
      postInstall = (oldAttrs.prePatch or "") + ''
        mkdir -p "$out/lib/${super.python.libPrefix}/site-packages/jupytext/labextension"
        cp -r ./jupytext/labextension/* "$out/lib/${super.python.libPrefix}/site-packages/jupytext/labextension/"

        mkdir -p "$out/share/jupyter/labextensions/jupytext"
        cp -r ./jupytext/labextension/* "$out/share/jupyter/labextensions/jupytext/"
      '';
    });

    python_magic = super.python_magic.overridePythonAttrs(oldAttrs: {
      propagatedBuildInputs = oldAttrs.propagatedBuildInputs ++ [pkgs.file];

      # Re-using the patch from nixpkgs.
      # strangely, specifying 'python_magic' works here but 'python-magic' does not.
      patches = pkgs.python3.pkgs.python_magic.patches or [ ];

      checkInputs = [ pkgs.glibcLocales ];
      doCheck = true;
      # TODO: Do the full test. It currently fails because ./test/testdata/ is
      #       not available. Maybe that dir isn't downloaded via PyPI?
      checkPhase = ''
        if python -c 'import magic; print(magic)'; then
          echo "python-magic is importable" >&2
        else
          echo "python-magic test failed" >&2
          exit 1
        fi
      '';
    });
    python-magic = super.python_magic;

    # jupytext depends on markdown-it-py[plugins]
    #
    # markdown-it-py and mdit-py-plugins are currently cyclic dependencies.
    #
    # markdown-it-py depends on mdit-py-plugins as an extension and uses
    # it during testing. Maybe it will eventually be removed as a dependency?
    #
    # The only way to install them is to explicitly require both:
    #   poetry add --lock mdit-py-plugins markdown-it-py
    #
    # But then tell markdown-it-py that it doesn't depend on mdit-py-plugins,
    # even though it actually does.
    markdown-it-py = super.markdown-it-py.overridePythonAttrs(oldAttrs: {
      # TODO: The following will need to be updated every time one of the
      #       versions changes. Is there a better replace expression?
      preConfigure = ''
        substituteInPlace setup.py --replace \
          'install_requires=["attrs>=19,<21", "mdit-py-plugins~=0.2.1"],' 'install_requires=["attrs>=19,<21"],'
      '';

      # markdown-it-py[plugins]>=1.0.0b3,<2.0.0


      #ERROR: Could not find a version that satisfies the requirement mdit-py-plugins; extra == "plugins"
      #(from markdown-it-py[plugins]<2.0.0,>=1.0.0b3->jupytext==1.11.2) (from versions: none)
       
      # TODO: right now, the only dependencies in setup.py are attrs and
      #       mdit-py-plugins, but if a new dependency is added, this
      #       expression will no longer work. However, using subtractLists
      #       doesn't work, because it makes mdit-py-plugins dependency again. 
      propagatedBuildInputs = [super.attrs];
      #propagatedBuildInputs = lib.subtractLists [super.mdit-py-plugins] oldAttrs.propagatedBuildInputs;
       
      # The tests for markdown-it-py currently depend on mdit-py-plugins.
      # But the tests for mdit-py-plugins are presumably still enabled,
      # so maybe we still do test markdown-it-py that way?
      doCheck = false;
    });

    ############
    # matplotlib
    ############

    matplotlib = super.matplotlib.overridePythonAttrs (
      old:
      let 
        enableGhostscript = old.passthru.enableGhostscript or false;
        enableGtk3 = old.passthru.enableTk or false;
        enableQt = old.passthru.enableQt or false;
        enableTk = old.passthru.enableTk or false;

        inherit (pkgs.darwin.apple_sdk.frameworks) Cocoa;
      in  
      {   
        NIX_CFLAGS_COMPILE = lib.optionalString stdenv.isDarwin "-I${pkgs.libcxx}/include/c++/v1";

        XDG_RUNTIME_DIR = "/tmp";

        buildInputs = (old.buildInputs or [ ])
          ++ lib.optional enableGhostscript pkgs.ghostscript
          ++ lib.optional stdenv.isDarwin [ Cocoa ];

        nativeBuildInputs = (old.nativeBuildInputs or [ ]) ++ [
          pkgs.pkg-config
        ];  

        postPatch = ''
          cat > setup.cfg <<EOF
          [libs]
          system_freetype = true
          system_qhull = true
          EOF
        '';

        propagatedBuildInputs = old.propagatedBuildInputs ++ [
          pkgs.libpng
          pkgs.freetype
          pkgs.qhull
          super.certifi
        ]   
          ++ lib.optionals enableGtk3 [ pkgs.cairo self.pycairo pkgs.gtk3 pkgs.gobject-introspection self.pygobject3 ]
          ++ lib.optionals enableTk [ pkgs.tcl pkgs.tk self.tkinter pkgs.libX11 ]
          ++ lib.optionals enableQt [ self.pyqt5 ]
        ;   

        doCheck = false;

        inherit (super.matplotlib) patches;
      }   
    );

    ###########
    # nbconvert
    ###########

    # jupyter-nbconvert is for ipynb -> read-only formats, e.g., pdf, html, etc.
    #
    # Sample conversions:
    # jupyter-nbconvert notebooks/sandbox.py.ipynb --to html
    # jupyter-nbconvert notebooks/sandbox.py.ipynb --to pdf
    # jupyter-nbconvert notebooks/sandbox.py.ipynb --to latex


    nbconvert = super.nbconvert.overridePythonAttrs(oldAttrs: {
      propagatedBuildInputs = (oldAttrs.propagatedBuildInputs or []) ++ [ pkgs.pandoc pkgs.texlive.combined.scheme-full ];
    });

    # nbconvert dependencies:
    #p.pandoc
    # see https://github.com/jupyter/nbconvert/issues/808
    # TODO: is tectonic needed? It appears I can convert to pdf & latex w/out it.
    #p.tectonic
    # more info: https://nixos.wiki/wiki/TexLive
    #p.texlive.combined.scheme-full

    # still getting some errors for certain types of conversions:
    # nbconvert failed: Pyppeteer is not installed to support Web PDF conversion. Please install `nbconvert[webpdf]` to enable.
    # - and -
    # nbconvert failed: PDF creating failed, captured latex output:
    # Failed to run "['xelatex', 'notebook.tex', '-quiet']" command:
    # ...
    # (/nix/store/llmvlb5wpjrmp4ckxw4g21qn4syyhjpv-texlive-combined-full-2020.2021010
    # 9/share/texmf/tex/latex/base/size11.cloFontconfig warning: "/etc/fonts/fonts.conf", line 86: unknown element "blank"
    # ))

    ###########
    # ndex2
    ###########

    ndex2 = super.ndex2.overridePythonAttrs(oldAttrs: {
      # The source requiremets.txt appears to want:
      #   if python < 3, use enum
      #   if python 3 but < 3.4, use enum34
      # But the way it's specified doesn't work for python >= 3.4.
      # I'm just telling it to use enum34 whenever python < 3.4
#      prePatch = (oldAttrs.prePatch or "") + ''
#        substituteInPlace setup.py \
#            --replace 'enum34' 'enum34; python_version < "3.4"'
#      '';

#      propagatedBuildInputs = [
#        six ijson requests requests-toolbelt networkx urllib3 pandas pysolr numpy
#      ] ++ lib.optionals (pkgs.python3.pythonOlder "3.4") [ enum34 ];

      #propagatedBuildInputs = oldAttrs.propagatedBuildInputs ++ lib.optionals (pkgs.python3.pythonOlder "3.4") [ enum34 ];

#      checkInputs = [
#        nose six ijson requests requests-toolbelt networkx urllib3 pandas pysolr numpy
#      ];
#
#      checkPhase = ''
#        nosetests -v
#      '';

      # These tests attempt to make network requests, so Nix can't run them.
      doCheck = false;
    });

    regex = super.regex.overridePythonAttrs (
      old: {
        nativeBuildInputs = (old.nativeBuildInputs or [ ]) ++ [ self.cython ];

        # from nixpkgs
        postCheck = ''
          if python -c 'import regex; print(regex)'; then
            echo "regex is importable" >&2
          else
            echo "regex test failed" >&2
            exit 1
          fi

          echo "We now run tests ourselves, since the setuptools installer doesn't."
          python -c 'import test_regex; test_regex.test_main();'
        '';

        # No tests in archive
        doCheck = false;
      }
    );

    rpy2 = super.rpy2.overridePythonAttrs(oldAttrs: {
      nativeBuildInputs = oldAttrs.nativeBuildInputs ++ [
        R # needed at setup time to detect R_HOME (alternatively set R_HOME explicitly)
      ];
      # TODO: What type of input should R be?
      #propagatedBuildInputs = oldAttrs.propagatedBuildInputs ++ [ R ];

      prePatch = (oldAttrs.prePatch or "") + ''
        export R_HOME="${R}/lib/R"
        export R_LIBS_SITE="$R_LIBS_SITE''${R_LIBS_SITE:+:}${R}/lib/R/library"
      '';

      # TODO: do we need to add to LD_LIBRARY_PATH, or is that handled elsewhere?
      # export LD_LIBRARY_PATH="$(python -m rpy2.situation LD_LIBRARY_PATH)":${LD_LIBRARY_PATH}
      #
      # even more minimal and also seems to still work:
      # export LD_LIBRARY_PATH="/nix/store/g9ajhxyzwzqriv4sv326szrgx9rhq7as-R-3.6.3/lib/R/lib:LD_LIBRARY_PATH"

      patches = [
        # R_LIBS_SITE is used by the Nix R package to point to the installed R packages.
        # This patch sets R_LIBS_SITE when rpy2 is imported.
        # As currently configured, it only gets the 'Priority: base' packages.
        # Is it intended that other packages be included too?
        ./rpy2-3.x-r-libs-site.patch
      ];

      # Obtained the patch like this:
      # * created dirs a and b
      # * put original file in a
      # * put edited file in b
      # * ran the following:
      # diff -u a/rpy2/rinterface_lib/embedded.py b/rpy2/rinterface_lib/embedded.py >xpm2nix/python-modules/rpy2-3.x-r-libs-site.patch

      postPatch = ''
        substituteInPlace 'rpy2/rinterface_lib/embedded.py' --replace '@NIX_R_LIBS_SITE@' "$R_LIBS_SITE"
      '';

      checkPhase = (oldAttrs.checkPhase or "") + ''
        if ! python -m rpy2.situation; then
          echo "Error: rpy2 returned non-zero for 'python -m rpy2.situation'"
          exit 1
        fi
      '';
    });

    wand = super.wand.overridePythonAttrs(oldAttrs: {
      propagatedBuildInputs = oldAttrs.propagatedBuildInputs ++ [pkgs.imagemagick7Big];

      # Re-using the patch from nixpkgs.
      #patches = pkgs.python3.pkgs.wand.patches or [ ];
      postPatch = pkgs.python3.pkgs.Wand.postPatch;

      #passthru.imagemagick = imagemagick7Big;
      passthru = pkgs.python3.pkgs.Wand.passthru;

      doCheck = true;
      checkPhase = ''
        if python -c 'import wand; print(wand)'; then
          echo "wand is importable" >&2
        else
          echo "wand test failed" >&2
          exit 1
        fi
      '';
    });
    Wand = super.wand;

    ##############
    # spacy & deps
    ##############

    blis = super.blis.overridePythonAttrs (
      old: {
        nativeBuildInputs = (old.nativeBuildInputs or [ ]) ++ [ self.cython ];
      }
    );

    cymem = super.cymem.overridePythonAttrs (
      old: {
        nativeBuildInputs = (old.nativeBuildInputs or [ ]) ++ [ self.cython ];
      }
    );

    murmurhash = super.murmurhash.overridePythonAttrs (
      old: {
        nativeBuildInputs = (old.nativeBuildInputs or [ ]) ++ [ self.cython ];
      }
    );

    preshed = super.preshed.overridePythonAttrs (
      old: {
        nativeBuildInputs = (old.nativeBuildInputs or [ ]) ++ [ self.cython ];
      }
    );

    srsly = super.srsly.overridePythonAttrs (
      old: {
        nativeBuildInputs = (old.nativeBuildInputs or [ ]) ++ [ self.cython ];
      }
    );

    thinc = super.thinc.overridePythonAttrs (
      old: {
        nativeBuildInputs = (old.nativeBuildInputs or [ ]) ++ [ self.cython ];
      }
    );

    spacy = super.spacy.overridePythonAttrs (
      old: {
        nativeBuildInputs = (old.nativeBuildInputs or [ ]) ++ [ self.cython ];
      }
    );

  });
in
  {
    poetryEnv = poetry2nix.mkPoetryEnv {
      projectDir = ./.;
      overrides = overrides;
    };
    poetryPackages = poetry2nix.mkPoetryPackages {
      projectDir = ./.;
      overrides = overrides;
    };
  }
