{ pkgs }:

let
  inherit (pkgs)
    lib
    stdenvNoCC
    fetchurl
    ;

  pname = "moshi-hook";
  version = "0.2.85";

  sources = {
    x86_64-linux = {
      asset = "moshi-hook_Linux_x86_64.tar.gz";
      hash = "sha256-UHHGeBy3ehWGAKuUQ3rxVE6BkyCChxktwzPA1Xuk1bY=";
    };

    aarch64-linux = {
      asset = "moshi-hook_Linux_arm64.tar.gz";
      hash = "sha256-dx4ojKk5yqQ851Wa10CprSp0dPt1Wi3zx+k2FvWAhgs=";
    };
  };

  source =
    sources.${stdenvNoCC.hostPlatform.system}
      or (throw "Unsupported system for ${pname}: ${stdenvNoCC.hostPlatform.system}");
in
stdenvNoCC.mkDerivation {
  inherit pname version;

  src = fetchurl {
    url = "https://cdn.getmoshi.app/hook/v${version}/${source.asset}";
    inherit (source) hash;
  };

  sourceRoot = ".";

  # The upstream installer also links `moshi` to the same binary, and the app's
  # pairing instructions name it, so the alias is part of the package rather
  # than something to remember on the next machine.
  installPhase = ''
    runHook preInstall

    install -Dm755 moshi-hook "$out/bin/moshi-hook"
    ln -s moshi-hook "$out/bin/moshi"

    runHook postInstall
  '';

  meta = {
    description = "Host-side hook for the Moshi mobile terminal: Easy Pair and agent notifications";
    homepage = "https://getmoshi.app";
    license = lib.licenses.unfree;
    mainProgram = "moshi-hook";
    platforms = builtins.attrNames sources;
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
  };
}
