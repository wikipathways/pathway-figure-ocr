{ stdenv, python3 }:

let
  inherit (python3.pkgs) buildPythonPackage fetchPypi;
in

buildPythonPackage rec {
  pname = "wikidata2df";
  version = "0.1.0";
  name = "${pname}-${version}";

  src = fetchPypi {
    inherit pname version;
    sha256 = "1rjs55jnmrbz4zpmiyascf5hiijvvw9r0zxc96ncvgw84cb4150s";
  };

  # setup_requires corresponds to nativeBuildInputs
  # install_requires corresponds to propagatedBuildInputs
  # tests_require corresponds to checkInputs
  #
  # See Nixpkgs Manual 15.19.3.10.
  # https://nixos.org/manual/nixpkgs/stable/#faq

  # TODO: pip gives this warning:
  #
  # Installing collected packages: wikidata2df
  #   WARNING: The script wikidata2csv is installed in '/nix/store/2spf1h1jxf6jn7k5ds98nsf6v1vgpdx2-python3.7-wikidata2df-0.1.0/bin' which is not on PATH.
  #   Consider adding this directory to PATH or, if you prefer to suppress this warning, use --no-warn-script-location.
  #
  # I found two ways to avoid that warning:
  # 1) add $out/bin to PATH, or
  # 2) ignore the warning
  #
  # What is the best way to handle it? It appears that even if I use
  # solution 2), 'wikidata2df' does end up on the path.

  # here's an example of 1)
#  configurePhase = ''
#    PATH=$PATH:$out/bin
#  '';

  # and here's 2)
  pipInstallFlags = ["--no-warn-script-location"];

  # The checkPhase for python maps to the installCheckPhase on a normal derivation.

  # It appears all the wikidata2df tests require network access.
  # We could just specify this:
  # doCheck = false;
  
  # But I wanted at least a minimal test: does the CLI shows help text?
  # TODO: are there better tests that don't require network access?

#  # For Solution 1), wikidata2csv is on the PATH, so I can just use 'wikidata2csv'
#  checkPhase = ''
#    wikidata2csv --help >/dev/null
#  '';
  # Solution 2) requires using '$out/bin/wikidata2csv'
  checkPhase = ''
    $out/bin/wikidata2csv --help >/dev/null
  '';

  # The following almost 'works' (by disabling all tests), but it gives an error
  # of some sort.
  # Maybe it's expecting something returns an exit code of 0?
#  checkInputs = with python3.pkgs; [pytest];
#  checkPhase = ''
#    pytest tests/ -k 'not test_wikidata2df_horse and not test_wikidata2df_cat and not test_wdt2csv and not test_fake_query'
#  '';

#  # The following should be equivalent to the code above, but
#  # it doesn't disable the tests.
#  #
#  # 15.19.1.2.5. Using pytestCheckHook
#  # https://nixos.org/manual/nixpkgs/stable/#faq
#  checkInputs = with python3.pkgs; [ pytestCheckHook ];
#  pytestFlagsArray = [ "tests/" ];
#  disabledTests = [
#    # touches network
#    "test_wikidata2df_horse"
#    "test_wikidata2df_cat"
#    "test_wdt2csv"
#    "test_fake_query"
#  ];

  nativeBuildInputs = with python3.pkgs; [pytestrunner];

  propagatedBuildInputs = with python3.pkgs; [
    pandas
    requests
  ];

  meta = with stdenv.lib; {
    description = "Utility package for easily turning a SPARQL query into a dataframe";
    homepage = "https://pypi.org/project/wikidata2df/";
    license = licenses.bsd3;
    maintainers = with maintainers; [ ];
  };
}
