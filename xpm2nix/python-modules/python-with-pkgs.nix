{pkgs, poetry2nix, R, lib, pythonOlder}:

with builtins;
let
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

    jupyterlab-vim = self.callPackage ./jupyterlab-vim.nix {jupyter-packaging=self.jupyter-packaging;};
    jupyterlab-vimrc = self.callPackage ./jupyterlab-vimrc.nix {};

    jupyterlab-widgets = super.jupyterlab-widgets.overridePythonAttrs(oldAttrs: {
      nativeBuildInputs = oldAttrs.nativeBuildInputs ++ [
        super.jupyter-packaging
      ];
    });

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
#      ] ++ lib.optionals (pythonOlder "3.4") [ enum34 ];

      #propagatedBuildInputs = oldAttrs.propagatedBuildInputs ++ lib.optionals (pythonOlder "3.4") [ enum34 ];

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

#    seaborn = super.seaborn.overridePythonAttrs(oldAttrs: {
#      nativeBuildInputs = (oldAttrs.nativeBuildInputs or []) ++ [
#        super.jupyter-packaging
#      ];
#      buildInputs = (oldAttrs.buildInputs or []) ++ [
#        super.certifi
#      ];
#    });

  });
in
  {
    poetryEnv = poetry2nix.mkPoetryEnv {
      projectDir = ./.;
      overrides = overrides;
    };
    topLevelPythonPackages = (poetry2nix.mkPoetryPackages {
      projectDir = ./.;
      overrides = overrides;
    }).poetryLock.package;
  }
