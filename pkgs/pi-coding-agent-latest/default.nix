{ pkgs }:

let
  inherit (pkgs) lib stdenv fetchurl glibc;

  pname = "pi-coding-agent-latest";
  version = "1.0.0";

  sources = {
    x86_64-linux = {
      platform = "linux-x64";
      hash = "sha256-j9VUOlKoidYK1XzL9slp5zx1xSQKrhisQLUGlHpj3Dg=";
    };
    aarch64-linux = {
      platform = "linux-arm64";
      hash = "sha256-tgs/2oMKQ8HcP17bX8e2gfIqCpMLSM2sE7l1cMYEWBk=";
    };
  };

  source = sources.${stdenv.hostPlatform.system}
    or (throw "Unsupported system for ${pname}: ${stdenv.hostPlatform.system}");

  # Keep the standalone runtime and its companion assets together. As with
  # Claude's bundled executable, do not rewrite the ELF or strip the payload.
  rawPackage = stdenv.mkDerivation {
    pname = "${pname}-binary";
    inherit version;

    src = fetchurl {
      url = "https://github.com/earendil-works/pi/releases/download/v${version}/pi-${source.platform}.tar.gz";
      inherit (source) hash;
    };

    dontConfigure = true;
    dontBuild = true;
    dontPatchELF = true;
    dontStrip = true;

    installPhase = ''
      runHook preInstall
      mkdir -p "$out/libexec/pi"
      cp -a . "$out/libexec/pi/"
      runHook postInstall
    '';
  };
in
pkgs.buildFHSEnv {
  name = "${pname}-${version}";

  targetPkgs = _: [
    glibc
    stdenv.cc.cc.lib
  ];

  runScript = "${rawPackage}/libexec/pi/pi";

  extraInstallCommands = ''
    ln -s "$out/bin/${pname}-${version}" "$out/bin/pi"
  '';

  meta = with lib; {
    description = "Pi coding agent CLI (official standalone release)";
    homepage = "https://pi.dev";
    license = licenses.mit;
    mainProgram = "pi";
    platforms = builtins.attrNames sources;
    sourceProvenance = [ sourceTypes.binaryNativeCode ];
  };
}
