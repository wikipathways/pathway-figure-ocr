with builtins;

let
  components = import ./jupyterEnvironment.nix;
  jupyterEnvironment = components.jupyterEnvironment;
  hook = components.hook;
in
  jupyterEnvironment.env.overrideAttrs (oldAttrs: {
    shellHook = oldAttrs.shellHook + hook;
  })
