{ lib
, buildPythonPackage
, fetchPypi
, jupyterlab
, jupyter_packaging
, setuptools
#, distutils
, wheel
#, nodejs
#, nodePackages
}:

# TODO: the standard setuptools build/install process fails.
# This Nix definition as written does get the prebuilt labextension, but it
# does not use the standard setuptools build/install. Is it OK?
#
# Which dependencies are actually needed? They are haphazardly defined here.

buildPythonPackage rec {
  pname = "jupyterlab_vim";
  version = "0.13.0";
  name = "${pname}-${version}";

  src = fetchPypi {
    inherit pname version;
    sha256 = "1frhk6k3f7xjw66bdr6zfxz1m3a1zfv8s192v2gq7v6g21p53kp6";
  };

  #nativeBuildInput = [ setuptools wheel nodePackages.typescript ];
  nativeBuildInput = [ setuptools wheel ];
  buildInputs = [ jupyter_packaging ];
  #propagatedBuildInputs = [ jupyterlab nodejs ];
  propagatedBuildInputs = [ jupyterlab ];

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

  meta = with lib; {
    description = "Code cell vim bindings.";
    longDescription = "Disclaimer: fork of https://github.com/jwkvam/jupyterlab-vim for personal use. Use at your own risk. The previous one doesn't appear to be active any more, but this one is.";
    homepage = "https://pypi.org/project/jupyterlab-vim/";
    license = licenses.bsd3;
    maintainers = [];
  };
}
