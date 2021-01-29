_: pkgs:
let
  packageOverrides = selfPythonPackages: pythonPackages: {
    nb_black = selfPythonPackages.callPackage ./nixpkgs/nb_black/default.nix {};
    seaborn = selfPythonPackages.callPackage ./nixpkgs/seaborn/default.nix {};
    skosmos_client = selfPythonPackages.callPackage ./nixpkgs/skosmos_client/default.nix {};
    wikidata2df = selfPythonPackages.callPackage ./nixpkgs/wikidata2df/default.nix {};
    homoglyphs = selfPythonPackages.callPackage ./nixpkgs/homoglyphs/default.nix {};
    confusable-homoglyphs = selfPythonPackages.callPackage ./nixpkgs/confusable-homoglyphs/default.nix {};
    pyahocorasick = selfPythonPackages.callPackage ./nixpkgs/pyahocorasick/default.nix {};
  };

in

{
  python3 = pkgs.python3.override (old: {
    packageOverrides =
      pkgs.lib.composeExtensions
        (old.packageOverrides or (_: _: {}))
        packageOverrides;
  });
}
