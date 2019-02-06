# generated using pypi2nix tool (version: 1.8.1)
# See more at: https://github.com/garbas/pypi2nix
#
# COMMAND:
#   pypi2nix -V 3 -e homoglyphs==1.3.2 -e confusable_homoglyphs==3.2.0 -e bs4
#

{ pkgs ? import <nixpkgs> {}
}:

let

  inherit (pkgs) makeWrapper;
  inherit (pkgs.stdenv.lib) fix' extends inNixShell;

  pythonPackages =
  import "${toString pkgs.path}/pkgs/top-level/python-packages.nix" {
    inherit pkgs;
    inherit (pkgs) stdenv;
    python = pkgs.python3;
    # patching pip so it does not try to remove files when running nix-shell
    overrides =
      self: super: {
        bootstrapped-pip = super.bootstrapped-pip.overrideDerivation (old: {
          patchPhase = old.patchPhase + ''
            sed -i               -e "s|paths_to_remove.remove(auto_confirm)|#paths_to_remove.remove(auto_confirm)|"                -e "s|self.uninstalled = paths_to_remove|#self.uninstalled = paths_to_remove|"                  $out/${pkgs.python35.sitePackages}/pip/req/req_install.py
          '';
        });
      };
  };

  commonBuildInputs = [];
  commonDoCheck = false;

  withPackages = pkgs':
    let
      pkgs = builtins.removeAttrs pkgs' ["__unfix__"];
      interpreter = pythonPackages.buildPythonPackage {
        name = "python3-interpreter";
        buildInputs = [ makeWrapper ] ++ (builtins.attrValues pkgs);
        buildCommand = ''
          mkdir -p $out/bin
          ln -s ${pythonPackages.python.interpreter}               $out/bin/${pythonPackages.python.executable}
          for dep in ${builtins.concatStringsSep " "               (builtins.attrValues pkgs)}; do
            if [ -d "$dep/bin" ]; then
              for prog in "$dep/bin/"*; do
                if [ -f $prog ]; then
                  ln -s $prog $out/bin/`basename $prog`
                fi
              done
            fi
          done
          for prog in "$out/bin/"*; do
            wrapProgram "$prog" --prefix PYTHONPATH : "$PYTHONPATH"
          done
          pushd $out/bin
          ln -s ${pythonPackages.python.executable} python
          ln -s ${pythonPackages.python.executable}               python3
          popd
        '';
        passthru.interpreter = pythonPackages.python;
      };
    in {
      __old = pythonPackages;
      inherit interpreter;
      mkDerivation = pythonPackages.buildPythonPackage;
      packages = pkgs;
      overrideDerivation = drv: f:
        pythonPackages.buildPythonPackage (drv.drvAttrs // f drv.drvAttrs //                                            { meta = drv.meta; });
      withPackages = pkgs'':
        withPackages (pkgs // pkgs'');
    };

  python = withPackages {};

  generated = self: {

    "beautifulsoup4" = python.mkDerivation {
      name = "beautifulsoup4-4.7.1";
      src = pkgs.fetchurl { url = "https://files.pythonhosted.org/packages/80/f2/f6aca7f1b209bb9a7ef069d68813b091c8c3620642b568dac4eb0e507748/beautifulsoup4-4.7.1.tar.gz"; sha256 = "945065979fb8529dd2f37dbb58f00b661bdbcbebf954f93b32fdf5263ef35348"; };
      doCheck = commonDoCheck;
      buildInputs = commonBuildInputs;
      propagatedBuildInputs = [
      self."soupsieve"
    ];
      meta = with pkgs.stdenv.lib; {
        homepage = "http://www.crummy.com/software/BeautifulSoup/bs4/";
        license = licenses.mit;
        description = "Screen-scraping library";
      };
    };



    "bs4" = python.mkDerivation {
      name = "bs4-0.0.1";
      src = pkgs.fetchurl { url = "https://files.pythonhosted.org/packages/10/ed/7e8b97591f6f456174139ec089c769f89a94a1a4025fe967691de971f314/bs4-0.0.1.tar.gz"; sha256 = "36ecea1fd7cc5c0c6e4a1ff075df26d50da647b75376626cc186e2212886dd3a"; };
      doCheck = commonDoCheck;
      buildInputs = commonBuildInputs;
      propagatedBuildInputs = [
      self."beautifulsoup4"
    ];
      meta = with pkgs.stdenv.lib; {
        homepage = "https://pypi.python.org/pypi/beautifulsoup4";
        license = licenses.mit;
        description = "Screen-scraping library";
      };
    };



    "confusable-homoglyphs" = python.mkDerivation {
      name = "confusable-homoglyphs-3.2.0";
      src = pkgs.fetchurl { url = "https://files.pythonhosted.org/packages/62/55/0aac1a100d755987e62c12367724b33419ed15921c6a915dc257c886ceff/confusable_homoglyphs-3.2.0.tar.gz"; sha256 = "3b4a0d9fa510669498820c91a0bfc0c327568cecec90648cf3819d4a6fc6a751"; };
      doCheck = commonDoCheck;
      buildInputs = commonBuildInputs;
      propagatedBuildInputs = [ ];
      meta = with pkgs.stdenv.lib; {
        homepage = "https://github.com/vhf/confusable_homoglyphs";
        license = licenses.mit;
        description = "Detect confusable usage of unicode homoglyphs, prevent homograph attacks.";
      };
    };



    "homoglyphs" = python.mkDerivation {
      name = "homoglyphs-1.3.2";
      src = pkgs.fetchurl { url = "https://files.pythonhosted.org/packages/26/ba/3744c57befd5d2b23858c6cf0c420ef3f4294d5243509fa35966e08ad3f1/homoglyphs-1.3.2.tar.gz"; sha256 = "cdb61c1ed4d23a1ec297e3c9a483dba2de171164b98afc3ed43862a91605f2fc"; };
      doCheck = commonDoCheck;
      buildInputs = commonBuildInputs;
      propagatedBuildInputs = [ ];
      meta = with pkgs.stdenv.lib; {
        homepage = "https://github.com/orsinium/homoglyphs";
        license = licenses.lgpl3Plus;
        description = "Get homoglyphs for text, convert text to ASCII.";
      };
    };



    "soupsieve" = python.mkDerivation {
      name = "soupsieve-1.7.3";
      src = pkgs.fetchurl { url = "https://files.pythonhosted.org/packages/a0/ac/fc877f0cfe74c8ca93eb2cd873786fd0b4e92e1cb8d8aaa82aa8fcfd259d/soupsieve-1.7.3.tar.gz"; sha256 = "87db12ae79194f0ff9808d2b1641c4f031ae39ffa3cab6b907ea7c1e5e5ed445"; };
      doCheck = commonDoCheck;
      buildInputs = commonBuildInputs;
      propagatedBuildInputs = [ ];
      meta = with pkgs.stdenv.lib; {
        homepage = "https://github.com/facelessuser/soupsieve";
        license = licenses.mit;
        description = "A CSS4 selector implementation for Beautiful Soup.";
      };
    };

  };
  localOverridesFile = ./requirements_override.nix;
  overrides = import localOverridesFile { inherit pkgs python; };
  commonOverrides = [

  ];
  allOverrides =
    (if (builtins.pathExists localOverridesFile)
     then [overrides] else [] ) ++ commonOverrides;

in python.withPackages
   (fix' (pkgs.lib.fold
            extends
            generated
            allOverrides
         )
   )