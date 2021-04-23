{ stdenv
, lib
, callPackage
, fetchFromGitHub
, jq
, nodejs
, jupyter
, jupyterlab
, setuptools
}:

with builtins;

let
  baseName = "my-prebuilt-npm-jupyter-labextensions";
  version = "0.0.0";
  nodeDependencies = (callPackage ./default.nix {}).shell.nodeDependencies;
in
stdenv.mkDerivation rec {
  name = (concatStringsSep "-" [baseName version]);

  srcs = [
    (fetchFromGitHub {
      owner = "arbennett";
      repo = "jupyterlab-themes";
      rev = "5bf0e7344ee655a2e9c94ca30fc46447c12f7fb7";
      sha256 = "06vnrcqmi9s5y400lnq46wz07555s32zzmpadm7f5gaxkzgx225q";
    })
    # I could add the following too, but these are already on PyPI:
#    (fetchFromGitHub {
#      owner = "jupyterlab";
#      repo = "jupyter-renderers";
#      rev = "@jupyterlab/geojson-extension@3.1.2";
#      sha256 = "0f3dilz1zxfnfmj4a0m62d3xr437vpn3fr8wr88y45s7vfp60bbf";
#    })
  ];

  sourceRoot = ".";

  unpackPhase = ''
    runHook preUnpack

    mkdir source

    for _src in $srcs; do
      cp -r "$_src" $(stripHash "$_src")
      chmod -R +w $(stripHash "$_src")
    done

    runHook postUnpack
  '';

  buildInputs = [
    jq
    nodejs
    nodeDependencies
    jupyter
    jupyterlab

    # if I don't include setuptools, I get this error:
    # ModuleNotFoundError: No module named 'pkg_resources'
    setuptools
  ];

  buildPhase = ''
    mkdir -p "$out/labextensions"

    PREV_DIR="$(pwd)"

    export PATH="${nodeDependencies}/bin:$PATH"

    for f in $(find source/ -name "package.json"); do
      echo "f: $f";
      if [ $(jq '.jupyterlab.extension' "$f") = "true" ]; then
        labextension_name="$(jq -r '.name' "$f")"

        cd "$(dirname $f)"

        ln -s ${nodeDependencies}/lib/node_modules ./node_modules

        # patch package.json
        mv package.json old-package.json
        # TODO: how can I avoid this step, or at least better handle keeping up
        # with the correct version?
        jq '. * ({"devDependencies": {"@jupyterlab/builder": "^3.0.6"}})' old-package.json >package.json

        npm run build
        jupyter labextension build

        mkdir -p "$out/labextensions/$labextension_name"
        # TODO: only copy over package.json, install.json, static, schemas, etc.
        cp -r ./static/* "$out/labextensions/$labextension_name"

        cd "$PREV_DIR"
      fi;
    done
  '';

  # Should I move some of the buildPhase into here?
  installPhase =''
    echo 'installPhase' >&2
  '';

  meta = with lib;
    { description = "My custom set of JupyterLab extensions, sourced from NPM and prebuilt";
      maintainers = with maintainers; [ ariutta ];
      platforms = platforms.all;
    };
}
