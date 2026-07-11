{ pkgs }:

let
  inherit (pkgs)
    fetchurl
    lib
    patchelf
    stdenv
    ;

  pname = "opencode-v2";
  version = "0.0.0-next-15329";

  sources = {
    x86_64-linux = {
      package = "cli-linux-x64-baseline";
      hash = "sha256-nSsD7xTCFXYLkcEGsZ9m8xGF5puFtGEIwu7TFPshsyk=";
    };

    aarch64-linux = {
      package = "cli-linux-arm64";
      hash = "sha256-48du9mFsBafUxWsssjtTb7/R3oAN8bYlvypiwXZSDvA=";
    };
  };

  source =
    sources.${stdenv.hostPlatform.system}
      or (throw "Unsupported system for ${pname}: ${stdenv.hostPlatform.system}");
in
stdenv.mkDerivation {
  inherit pname version;

  src = fetchurl {
    url = "https://registry.npmjs.org/@opencode-ai/${source.package}/-/${source.package}-${version}.tgz";
    inherit (source) hash;
  };

  nativeBuildInputs = [ patchelf ];

  dontPatchELF = true;
  dontStrip = true;

  installPhase = ''
    runHook preInstall

    install -Dm755 bin/opencode2 "$out/libexec/opencode-v2/bin/opencode2"
    install -Dm644 package.json "$out/libexec/opencode-v2/package.json"
    mkdir -p "$out/bin"
    ln -s "$out/libexec/opencode-v2/bin/opencode2" "$out/bin/opencode2"
    patchelf --set-interpreter ${stdenv.cc.bintools.dynamicLinker} "$out/libexec/opencode-v2/bin/opencode2"

    runHook postInstall
  '';

  meta = with lib; {
    description = "Open source AI coding agent CLI v2 beta";
    homepage = "https://opencode.ai";
    license = licenses.mit;
    mainProgram = "opencode2";
    platforms = builtins.attrNames sources;
    sourceProvenance = [ sourceTypes.binaryNativeCode ];
  };
}
