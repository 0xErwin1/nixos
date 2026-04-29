{ pkgs }:

let
  inherit (pkgs) lib stdenv fetchurl;

  pname = "opencode";
  version = "1.14.25";

  sources = {
    x86_64-linux = {
      archive = "opencode-linux-x64-baseline.tar.gz";
      hash = "sha256-DCMs6MoxOImDxgcKPeWnPEzhGCDlsQBQRPEAD11X+iw=";
    };

    aarch64-linux = {
      archive = "opencode-linux-arm64.tar.gz";
      hash = "sha256-DO4hWJ1JNmGbzWExNCEhwNIO8kX77DFACcibP5M4NI0=";
    };
  };

  source =
    sources.${stdenv.hostPlatform.system}
      or (throw "Unsupported system for ${pname}: ${stdenv.hostPlatform.system}");

in
stdenv.mkDerivation {
    inherit pname version;

    src = fetchurl {
      url = "https://github.com/anomalyco/opencode/releases/download/v${version}/${source.archive}";
      inherit (source) hash;
    };

    dontUnpack = true;
    dontConfigure = true;
    dontBuild = true;
    dontStrip = true;

    installPhase = ''
      runHook preInstall

      unpackDir="$(mktemp -d)"
      tar -xzf "$src" -C "$unpackDir"

      install -Dm755 "$unpackDir/opencode" "$out/bin/opencode"

      runHook postInstall
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
