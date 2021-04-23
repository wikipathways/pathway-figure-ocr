# For more info, see
# http://datakurre.pandala.org/2015/10/nix-for-python-developers.html
# https://nixos.org/nixos/nix-pills/developing-with-nix-shell.html
# https://nixos.org/nix/manual/#sec-nix-shell

with builtins;
let
  # Importing overlays
  overlays = [];
  pkgs = import <nixpkgs> { inherit overlays; config.allowUnfree = true; };
in
  pkgs.stdenv.mkDerivation rec {
    name = "env";
    # Mandatory boilerplate for buildable env
    env = pkgs.buildEnv { name = name; paths = buildInputs; };
    builder = toFile "builder.sh" ''
      source $stdenv/setup; ln -s $env $out
    '';

    # Customizable development requirements
    buildInputs = with pkgs; [
      # for python
      python3
      poetry

      # for node
      pkgs.nodePackages.node2nix
      pkgs.nodejs # includes npm

      # yarn.lock <-> package-lock.json
      #pkgs.nodePackages.synp

      # node-gyp dependencies (node-gyp compiles C/C++ Addons)
      #   see https://github.com/nodejs/node-gyp#on-unix
      pkgs.python2
    ] ++ (if pkgs.stdenv.isDarwin then [
      # more node-gyp dependencies
      # XCode Command Line Tools
      # TODO: do we need cctools?
      #pkgs.darwin.cctools
    ] else [
      # more node-gyp dependencies
      pkgs.gnumake

      # gcc and binutils sometimes have a collision for .../bin/ld.gold
      # If this happens, try binutils or binutils-unwrapped to see whether
      # one them works even if the other fails.
      pkgs.gcc # also provides cc
      pkgs.binutils # provides ar
    ]);

    # Customizable development shell setup with at last SSL certs set
    shellHook = ''
      # this is needed in order that tools like curl and git can work with SSL
      # possibly only for direnv?
      if [ ! -f "$SSL_CERT_FILE" ] || [ ! -f "$NIX_SSL_CERT_FILE" ]; then
        candidate_ssl_cert_file=""
        if [ -f "$SSL_CERT_FILE" ]; then
          candidate_ssl_cert_file="$SSL_CERT_FILE"
        elif [ -f "$NIX_SSL_CERT_FILE" ]; then
          candidate_ssl_cert_file="$NIX_SSL_CERT_FILE"
        else
          candidate_ssl_cert_file="/etc/ssl/certs/ca-bundle.crt"
        fi
        if [ -f "$candidate_ssl_cert_file" ]; then
            export SSL_CERT_FILE="$candidate_ssl_cert_file"
            export NIX_SSL_CERT_FILE="$candidate_ssl_cert_file"
        else
          echo "Cannot find a valid SSL certificate file. curl will not work." >&2
        fi
      fi
      # TODO: is the following line ever useful?
      # maybe when using nix-shell?
      #export SSL_CERT_FILE=${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt
    '';
  }
