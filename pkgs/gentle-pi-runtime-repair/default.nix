{ pkgs }:

let
  repair = pkgs.writeShellApplication {
    name = "gentle-pi-runtime-repair";
    runtimeInputs = [ pkgs.nodejs ];
    text = ''
      usage() {
        echo "usage: gentle-pi-runtime-repair --prefix PATH | --package-dir PATH" >&2
        exit 2
      }
      [ "$#" -eq 2 ] || usage
      export GENTLE_PI_SKIP_GENTLE_AI_INSTALL=0
      case "$1" in
        --prefix)
          # An npm install: gentle-pi sits under node_modules and npm can
          # re-run its lifecycle scripts in place.
          if [ ! -f "$2/node_modules/gentle-pi/package.json" ]; then
            echo "gentle-pi is not installed under $2; nothing to repair" >&2
            exit 0
          fi
          exec npm rebuild --offline --ignore-scripts=false --prefix "$2" gentle-pi
          ;;
        --package-dir)
          # A git install: the checkout is the package itself, so the
          # postinstall runs from its own directory.
          if [ ! -f "$2/package.json" ]; then
            echo "no package at $2; nothing to repair" >&2
            exit 0
          fi
          cd "$2"
          exec npm run postinstall
          ;;
        *) usage ;;
      esac
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
