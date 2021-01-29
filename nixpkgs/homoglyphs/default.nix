{ lib
, buildPythonPackage
, fetchurl
}:

buildPythonPackage rec {
  pname = "homoglyphs";
  version = "1.3.2";
  src = fetchurl {
    url = "https://files.pythonhosted.org/packages/26/ba/3744c57befd5d2b23858c6cf0c420ef3f4294d5243509fa35966e08ad3f1/homoglyphs-1.3.2.tar.gz";
    sha256 = "cdb61c1ed4d23a1ec297e3c9a483dba2de171164b98afc3ed43862a91605f2fc";
  };

  doCheck = false;
  buildInputs = [ ];
  propagatedBuildInputs = [ ];
  meta = {
    homepage = "https://github.com/orsinium/homoglyphs";
    license = "GNU Lesser General Public License v3.0";
    description = "Get homoglyphs for text, convert text to ASCII.";
  };
}
