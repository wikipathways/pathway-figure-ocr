{ lib
, buildPythonPackage
, fetchPypi
, nose
, numpy
, scipy
, pandas
, matplotlib
, statsmodels
}:

buildPythonPackage rec {
  pname = "seaborn";
  version = "0.10.0";
  src = fetchPypi {
    inherit pname version;
    sha256 = "1ffbms4kllihfycf6j57dziq4imgdjw03sqgifh5wzcd2d743zjr";
  };

  checkInputs = [ nose ];
  propagatedBuildInputs = [ pandas matplotlib ];

  checkPhase = ''
    nosetests -v
  '';

  # Computationally very demanding tests
  doCheck = false;

  meta = {
    description = "Statistical data visualization";
    homepage = "https://seaborn.pydata.org/";
    license = with lib.licenses; [ bsd3 ];
    maintainers = with lib.maintainers; [ fridh ];
  };
}
