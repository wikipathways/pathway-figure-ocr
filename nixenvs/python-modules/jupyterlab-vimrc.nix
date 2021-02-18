{ lib
, buildPythonPackage
, fetchPypi
, setuptools
, jupyterlab
}:

buildPythonPackage rec {
  pname = "jupyterlab-vimrc";
  version = "0.5.2";
  name = "${pname}-${version}";

  src = fetchPypi {
    inherit pname version;
    sha256 = "1ylwk1hbrzyyhabmz9rgwp6qcmh5nyjy42dmav75wflgfhy0hazm";
  };

  doCheck = true;
  buildInputs = [ setuptools ];
  propagatedBuildInputs = [ jupyterlab ];

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


  meta = with lib; {
    description = "Add a basic vimrc to jupyterlab.";
    homepage = "https://pypi.org/project/jupyterlab-vimrc/";
    license = licenses.bsd3;
    maintainers = [];
  };
}
