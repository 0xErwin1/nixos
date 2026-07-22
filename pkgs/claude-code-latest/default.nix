{ pkgs }:

let
  inherit (pkgs)
    lib
    stdenv
    fetchurl
    glibc
    ;

  pname = "claude-code-latest";
  version = "2.1.217";

  sources = {
    x86_64-linux = {
      platform = "linux-x64";
      loader = "ld-linux-x86-64.so.2";
      hash = "sha256-JjD8XcbbYbwD+GuV2vR3ZuXtW2GHP3u3z+p2TFrFqbo=";
    };

    aarch64-linux = {
      platform = "linux-arm64";
      loader = "ld-linux-aarch64.so.1";
      hash = "sha256-QMU1B6xmnB1Dg2bBl2DCL1J0igblDg/A41PSy3NCVZc=";
    };
  };

  source =
    sources.${stdenv.hostPlatform.system}
      or (throw "Unsupported system for ${pname}: ${stdenv.hostPlatform.system}");

  # The release artifact is a Bun single-file executable: the JS bundle is
  # appended to the runtime and located by a byte offset stored in the binary.
  # patchelf/autoPatchelf rewrite the ELF and shift that offset, which makes Bun
  # silently fall back to its plain runtime CLI. Keep the binary untouched.
  rawPackage = stdenv.mkDerivation {
    pname = "${pname}-binary";
    inherit version;

    src = fetchurl {
      url = "https://downloads.claude.ai/claude-code-releases/${version}/${source.platform}/claude";
      inherit (source) hash;
    };

    dontUnpack = true;
    dontConfigure = true;
    dontBuild = true;
    dontPatchELF = true;
    dontStrip = true;

    installPhase = ''
      runHook preInstall
      install -Dm755 "$src" "$out/libexec/claude-code/claude"
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

  runScript = "${rawPackage}/libexec/claude-code/claude";

  profile = ''
    export DISABLE_AUTOUPDATER="\''${DISABLE_AUTOUPDATER:-1}"
  '';

  extraInstallCommands = ''
    ln -s "$out/bin/${pname}-${version}" "$out/bin/claude"
  '';

  meta = with lib; {
    description = "Anthropic Claude Code CLI (native Bun build, tracks the latest release)";
    homepage = "https://code.claude.com";
    license = licenses.unfree;
    mainProgram = "claude";
    platforms = builtins.attrNames sources;
    sourceProvenance = [ sourceTypes.binaryNativeCode ];
  };
}
