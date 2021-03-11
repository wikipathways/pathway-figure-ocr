with import <nixpkgs> {};

let
  #callPackage = pkgs.callPackage;
  #mergeAttrs = pkgs.lib.trivial.mergeAttrs;

  # The directory to use for notebooks and kernels.
  # https://jupyter-server.readthedocs.io/en/latest/other/full-config.html
  rootDir="/data";

  jupyterEnvironment = import ./default.nix;

#  components = callPackage ./jupyterEnvironment.nix {
#    shareJupyterDirectoryPrefix="";
#    rootDir=rootDir;
#  };
#
#  #pkgs = components.pkgs;
#  jupyterEnvironment = components.jupyterEnvironment;
#
#  contents = components.contents;
#  hook = components.hook;
#  #envs = envs;
#  entrypoint = components.entrypoint;
#  entrypoint = pkgs.writeScript "entrypoint.sh" ''
#    #!${pkgs.stdenv.shell}
#    set -e
#    # allow the container to be started with `--user`
#    exec "$@"
#  '';
#  entrypoint = writeScript "entrypoint.sh" ''
#    #!${pkgs.stdenv.shell}
#    set -e
#    # allow the container to be started with `--user`
#    exec "$@"
#  '';
in
#pkgs.dockerTools.buildLayeredImage {
pkgs.dockerTools.streamLayeredImage {
  name = "jupyter-image";
  tag = "latest";

#  runAsRoot = ''
#    #!${pkgs.stdenv.shell}
#    ${pkgs.dockerTools.shadowSetup}
#    mkdir /data
#    export BOO="wow1";
#    export BOO1="wow1";
#  '';

  contents = [
    jupyterEnvironment
  ];

  config = {
    Env = [
      "LOCALE_ARCHIVE=${pkgs.glibcLocales}/lib/locale/locale-archive"
      "LANG=en_US.UTF-8"
      "LANGUAGE=en_US:en"
      "LC_ALL=en_US.UTF-8"
    ] ++ [
      "JUPYTER_DATA_DIR=/share/jupyter"
      "JUPYTER_CONFIG_DIR=/share/jupyter/config"
      "JUPYTER_RUNTIME_DIR=/share/jupyter/runtime"
      "JUPYTERLAB_DIR=/share/jupyter/lab"
    ];
    #] ++ envs;

    #"PATH=$(dirname ${pkgs.stdenv.shell}):$PATH"
    Entrypoint = [ "/bin/jupyter-lab" "--ip=0.0.0.0" "--no-browser" "--allow-root" ];
    #Entrypoint = [ entrypoint ];
    WorkingDir = "/data";
    ExposedPorts = {
      "8888" = {};
    };
    Volumes = {
      "/data" = {};
    };
  };
}
