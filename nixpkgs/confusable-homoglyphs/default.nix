{ lib
, buildPythonPackage
, fetchurl
}:

buildPythonPackage rec {
  pname = "confusable-homoglyphs";
  version = "3.2.0";
  src = fetchurl {
    url = "https://files.pythonhosted.org/packages/62/55/0aac1a100d755987e62c12367724b33419ed15921c6a915dc257c886ceff/confusable_homoglyphs-3.2.0.tar.gz";
    sha256 = "3b4a0d9fa510669498820c91a0bfc0c327568cecec90648cf3819d4a6fc6a751";
  };

  doCheck = false;
  buildInputs = [ ];
  propagatedBuildInputs = [ ];
  meta = {
    homepage = "https://github.com/vhf/confusable_homoglyphs";
    license = lib.licenses.mit;
    description = "Detect confusable usage of unicode homoglyphs, prevent homograph attacks.";
  };
}
