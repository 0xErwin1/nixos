{ pkgs }:

let
  inherit (pkgs) lib stdenv fetchurl glibc;

  pname = "pi-coding-agent-latest";
  version = "1.3.0";

  sources = {
    x86_64-linux = {
      platform = "linux-x64";
      hash = "sha256-JPW+Motm1No2h2KWmJUBl09Dq4Q0+7V8NcUjo+pQXe0=";
    };
    aarch64-linux = {
      platform = "linux-arm64";
      hash = "sha256-f9LqFPyjkOv59HQ4uq7wfEs9E9t8yORZgxEYORt+pls=";
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

  # gentle-shell's notification audio falls back to /usr/bin/paplay when its
  # native Pulse worker cannot run, which is always the case here: the worker is
  # spawned through process.execPath, and in this standalone build that is the
  # pi binary rather than Node.
  targetPkgs = _: [
    glibc
    stdenv.cc.cc.lib
    pkgs.pulseaudio
  ];

  runScript = "${rawPackage}/libexec/pi/pi";

  # buildFHSEnv's profile exports NIX_CFLAGS_LINK="-L/usr/lib -L/usr/lib32".
  # Nix dev shells entered from the agent inherit it, so their compilers link
  # against this environment's glibc instead of the shell's own, and the
  # resulting binaries fail to start ("GLIBC_2.xx not found").
  profile = ''
    unset NIX_CFLAGS_LINK
  '';

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
