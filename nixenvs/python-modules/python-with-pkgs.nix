{poetry2nix, R}:
# For more info, see
# http://datakurre.pandala.org/2015/10/nix-for-python-developers.html
# https://nixos.org/nixos/nix-pills/developing-with-nix-shell.html
# https://nixos.org/nix/manual/#sec-nix-shell

with builtins;
poetry2nix.mkPoetryEnv {
  projectDir = ./.;
  overrides = poetry2nix.overrides.withDefaults (self: super: {
    aquirdturtle-collapsible-headings = super.aquirdturtle-collapsible-headings.overridePythonAttrs(oldAttrs: {
      nativeBuildInputs = oldAttrs.nativeBuildInputs ++ [
        super.jupyter-packaging
      ];
    });
    jupyterlab = super.jupyterlab.overridePythonAttrs(oldAttrs: {
      nativeBuildInputs = oldAttrs.nativeBuildInputs ++ [
        super.jupyter-packaging
      ];
    });

#    seaborn = super.seaborn.overridePythonAttrs(oldAttrs: {
#      nativeBuildInputs = (oldAttrs.nativeBuildInputs or []) ++ [
#        super.jupyter-packaging
#      ];
#      buildInputs = (oldAttrs.buildInputs or []) ++ [
#        super.certifi
#      ];
#    });

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
      # diff -u a/rpy2/rinterface_lib/embedded.py b/rpy2/rinterface_lib/embedded.py >nixenvs/python-modules/rpy2-3.x-r-libs-site.patch

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
    jupyter-resource-usage = super.jupyter-resource-usage.overridePythonAttrs(oldAttrs: {
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
  });
}
