{ pkgs }:

let
  repair = pkgs.writeShellApplication {
    name = "gentle-pi-runtime-repair";
    runtimeInputs = [ pkgs.nodejs ];
    text = ''
      if [ "$#" -ne 2 ] || [ "$1" != "--prefix" ]; then
        echo "usage: gentle-pi-runtime-repair --prefix PATH" >&2
        exit 2
      fi

      prefix="$2"
      package="$prefix/node_modules/gentle-pi/package.json"
      if [ ! -f "$package" ]; then
        echo "gentle-pi is not installed in $prefix" >&2
        exit 1
      fi

      export GENTLE_PI_SKIP_GENTLE_AI_INSTALL=0
      exec npm rebuild --offline --ignore-scripts=false --prefix "$prefix" gentle-pi
    '';
  };
in
pkgs.buildFHSEnv {
  name = "gentle-pi-runtime-repair";

  # gentle-pi's original postinstall accepts only these absolute tar paths. The
  # FHS environment supplies one without changing the host or global PATH.
  targetPkgs = pkgs: [
    pkgs.bash
    pkgs.coreutils
    pkgs.findutils
    pkgs.gnutar
    pkgs.gzip
    pkgs.nodejs
  ];

  runScript = "${repair}/bin/gentle-pi-runtime-repair";
}
