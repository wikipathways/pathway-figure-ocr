{ lib
, buildPythonPackage
, fetchPypi
, python3
}:

buildPythonPackage rec {
  pname = "skosmos-client";
  version = "0.3.0";
  src = fetchPypi {
    inherit pname version;
    sha256 = "121drkk5mjsaxcdja43bacr57zzmm99s54ylyjw4iv46sxyj925y";
  };

  propagatedBuildInputs = with python3.pkgs;[
    requests rdflib
  ];

  # doCheck = false;

  meta = {
    description = "Client library for accessing Skosmos REST API endpoints";
    homepage = "https://github.com/NatLibFi/Skosmos-client";
    license = with lib.licenses; [ asl20 ];
    maintainers = with lib.maintainers; [ ariutta ];
  };
}
