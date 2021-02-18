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
  baseName = "base16-gruvbox-dark";
  version = "0.1.5";
  nodeDependencies = (callPackage ./default.nix {}).shell.nodeDependencies;
in
stdenv.mkDerivation rec {
  name = (concatStringsSep "-" [baseName version]);

  src = fetchFromGitHub {
    owner = "arbennett";
    repo = "jupyterlab-themes";
    rev = "5bf0e7344ee655a2e9c94ca30fc46447c12f7fb7";
    sha256 = "06vnrcqmi9s5y400lnq46wz07555s32zzmpadm7f5gaxkzgx225q";
  };

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
    cd base16-gruvbox-dark

    ln -s ${nodeDependencies}/lib/node_modules ./node_modules
    export PATH="${nodeDependencies}/bin:$PATH"

    # patch package.json
    mv package.json old-package.json
    jq '. * ({"devDependencies": {"@jupyterlab/builder": "3.0.3"}})' old-package.json >package.json

    npm run build
    jupyter labextension build

    cp -r ./static $out/
  '';

  installPhase =''
    echo 'installPhase' >&2
  '';

  meta = with lib;
    { description = "A JupyterLab theme extension";
      homepage = https://github.com/arbennett/jupyterlab-themes;
      license = licenses.bsd3;
      maintainers = with maintainers; [ ariutta ];
      platforms = platforms.all;
    };
}
