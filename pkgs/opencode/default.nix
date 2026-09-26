{ pkgs }:
let
  inherit (pkgs)
    lib
    stdenv
    fetchurl
    glibc
    ;

  pname = "opencode";
  version = "1.18.32";

  sources = {
    x86_64-linux = {
      archive = "opencode-linux-x64-baseline.tar.gz";
      hash = "sha256-djrzhu+IqMqxjfAPzwVWkOWlXjGnCIvqvgIwcUKmrc4=";
    };

    aarch64-linux = {
      archive = "opencode-linux-arm64.tar.gz";
      hash = "sha256-VoRht9TYwZhlyX6aEQLmEwScYDnQH+dyFU3oc8GGWEA=";
    };
  };

  source =
    sources.${stdenv.hostPlatform.system}
      or (throw "Unsupported system for ${pname}: ${stdenv.hostPlatform.system}");
  rawPackage = stdenv.mkDerivation {
    inherit pname version;

    src = fetchurl {
      url = "https://github.com/anomalyco/opencode/releases/download/v${version}/${source.archive}";
      inherit (source) hash;
    };

    dontUnpack = true;
    dontConfigure = true;
    dontBuild = true;
    dontPatchELF = true;
    dontStrip = true;

    installPhase = ''
      runHook preInstall

      unpackDir="$(mktemp -d)"
      tar -xzf "$src" -C "$unpackDir"

      install -Dm755 "$unpackDir/opencode" "$out/libexec/opencode/opencode"

      runHook postInstall
    '';
  };
in
pkgs.buildFHSEnv {
  name = "${pname}-${version}";

  targetPkgs = pkgs: [
    glibc
    stdenv.cc.cc.lib
  ];

  runScript = "${rawPackage}/libexec/opencode/opencode";

  profile = ''
    # The bwrap sandbox has no /etc/subuid and sets no_new_privs, so a local
    # rootless podman would create a single-UID pause namespace that every
    # later podman call of this user then joins. Route through the host API.
    podman_socket="''${XDG_RUNTIME_DIR:-/run/user/$(id -u)}/podman/podman.sock"
    if [ -S "$podman_socket" ]; then
      export CONTAINER_HOST="''${CONTAINER_HOST:-unix://$podman_socket}"
      export DOCKER_HOST="''${DOCKER_HOST:-unix://$podman_socket}"
    fi
    unset podman_socket
  '';

  extraInstallCommands = ''
    ln -s "$out/bin/${pname}-${version}" "$out/bin/opencode"
  '';

  meta = with lib; {
    description = "Open source AI coding agent CLI";
    homepage = "https://github.com/anomalyco/opencode";
    changelog = "https://github.com/anomalyco/opencode/releases/tag/v${version}";
    license = licenses.asl20;
    mainProgram = "opencode";
    platforms = builtins.attrNames sources;
    sourceProvenance = [ sourceTypes.binaryNativeCode ];
  };
}
