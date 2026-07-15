{
  lib,
  stdenv,
  fetchurl,
  autoPatchelfHook,
  makeWrapper,
}:

# Upstream ships a bundled Node runtime plus native addons per platform, so this
# fetches the prebuilt release archive for the host instead of building from npm.
# The npm build pulled arch-selected native/optional deps that were not cacheable
# for aarch64, which kept CodeGraph off the Pi; the prebuilt path works on both.
stdenv.mkDerivation (finalAttrs: {
  pname = "codegraph";
  version = "1.1.6";

  src =
    finalAttrs.passthru.sources.${stdenv.hostPlatform.system}
      or (throw "Unsupported system: ${stdenv.hostPlatform.system}");

  sourceRoot =
    {
      "aarch64-linux" = "codegraph-linux-arm64";
      "x86_64-linux" = "codegraph-linux-x64";
    }
    .${stdenv.hostPlatform.system} or (throw "Unsupported system: ${stdenv.hostPlatform.system}");

  strictDeps = true;

  nativeBuildInputs = [
    makeWrapper
    autoPatchelfHook
  ];

  buildInputs = [
    stdenv.cc.cc.lib
  ];

  dontConfigure = true;
  dontBuild = true;

  installPhase = ''
    runHook preInstall

    mkdir -p $out/lib/codegraph
    cp -r lib $out/lib/codegraph/lib
    cp node $out/lib/codegraph/node

    install -Dm 755 bin/codegraph $out/lib/codegraph/bin/codegraph

    mkdir -p $out/bin
    makeWrapper $out/lib/codegraph/bin/codegraph $out/bin/codegraph

    runHook postInstall
  '';

  passthru.sources = {
    "aarch64-linux" = fetchurl {
      url = "https://github.com/colbymchenry/codegraph/releases/download/v${finalAttrs.version}/codegraph-linux-arm64.tar.gz";
      hash = "sha256-/AvIClQh63x0FmYcn4cifSXWyN6O+S7IKodnd1rtfDo=";
    };
    "x86_64-linux" = fetchurl {
      url = "https://github.com/colbymchenry/codegraph/releases/download/v${finalAttrs.version}/codegraph-linux-x64.tar.gz";
      hash = "sha256-+rfx9stB8oJkiLRBHy68Ntp5km0ryg04IPT1EKvP0UM=";
    };
  };

  meta = {
    description = "Code intelligence and knowledge graph for any codebase (CLI + MCP)";
    homepage = "https://github.com/colbymchenry/codegraph";
    license = lib.licenses.mit;
    mainProgram = "codegraph";
    platforms = builtins.attrNames finalAttrs.passthru.sources;
    sourceProvenance = with lib.sourceTypes; [ binaryNativeCode ];
  };
})
