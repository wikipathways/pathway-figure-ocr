# For more info, see
# http://datakurre.pandala.org/2015/10/nix-for-python-developers.html
# https://nixos.org/nixos/nix-pills/developing-with-nix-shell.html
# https://nixos.org/nix/manual/#sec-nix-shell

with import <nixpkgs> { config.allowUnfree = true; };

with import ./custom_pkgs/requirements.nix { inherit pkgs; };
stdenv.mkDerivation rec {
  name = "env";
  # Mandatory boilerplate for buildable env
  env = buildEnv { name = name; paths = buildInputs; };
  builder = builtins.toFile "builder.sh" ''
    source $stdenv/setup; ln -s $env $out
  '';

  # Customizable development requirements
  buildInputs = [
    dos2unix
    # Add packages from nix-env -qaP | grep -i needle queries
    imagemagick
    inkscape
    postgresql

    # With Python configuration requiring a special wrapper
    # find names here: https://github.com/NixOS/nixpkgs/blob/release-17.03/pkgs/top-level/python-packages.nix
    (python37.buildEnv.override {
      ignoreCollisions = true;
      extraLibs = with python37Packages; [
        # Add pythonPackages without the prefix
        dill
        # TODO clean up how I'm specifying the homoglyphs package.
        # When I first tried it, I couldn't just add homoglyphs below like this:
        #homoglyphs
        # I had to install it using pypi2nix:
        #   (cd custom_pkgs; pypi2nix -V python37 -e homoglyphs==1.3.2)
        # and then use packages."homoglyphs", which looks ugly.
        packages."homoglyphs"
        idna
        pygpgme
        psycopg2
        requests
        Wand
      ];
    })
  ];

  # Customizable development shell setup with at last SSL certs set
  shellHook = ''
    export SSL_CERT_FILE=${cacert}/etc/ssl/certs/ca-bundle.crt
  '';
}
