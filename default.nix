with builtins;

let
  components = import ./jupyterEnvironment.nix;
  jupyterEnvironment = components.jupyterEnvironment;
  hook = components.hook;
in
  jupyterEnvironment.env.overrideAttrs (oldAttrs: {
    shellHook = oldAttrs.shellHook + hook;
    buildPhase = ''
      echo "I am building..." >&2
    '';

    # TODO: what's up with this?
    nobuildPhase = ''
      echo "The name is 'nobuildPhase', but maybe I do want to build something here?" >&2
      ls -lah ./*
      pwd
      exit 1
      mkdir -p $out
      cp ./* $out
    '';
  })
