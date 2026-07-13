{ pkgs }:

let
  inherit (pkgs)
    lib
    stdenv
    fetchurl
    glibc
    ;

  pname = "opencode";
  version = "1.17.18";

  sources = {
    x86_64-linux = {
      archive = "opencode-linux-x64-baseline.tar.gz";
      hash = "sha256-yB1cRpIgYE9lBrCdxGVovN1V0tTmP2tKwj5izNjBlHk=";
    };

    aarch64-linux = {
      archive = "opencode-linux-arm64.tar.gz";
      hash = "sha256-25tT6uSF2paaCoVbykZfmQHdhGdjhPck8yDjzMWpsQc=";
    };
  };

  source =
    sources.${stdenv.hostPlatform.system}
      or (throw "Unsupported system for ${pname}: ${stdenv.hostPlatform.system}");

in
let
  # The upstream archive ships a dynamically linked executable with the generic
  # Linux loader path (/lib64/ld-linux-*.so.*). Keep the ELF untouched and run it
  # inside an FHS environment so hosts do not need nix-ld enabled.
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
