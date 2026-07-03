{ pkgs }:

let
  inherit (pkgs)
    autoPatchelfHook
    fetchurl
    lib
    stdenv
    ;

  pname = "codexbar";
  version = "0.38.0";

  sources = {
    x86_64-linux = {
      arch = "x86_64";
      hash = "sha256-+5UmYCrC0S6BkwXKGV7qILMHYTeIU8YQKJl+9dNyygQ=";
    };

    aarch64-linux = {
      arch = "aarch64";
      hash = "sha256-LcVZshZFDH02xXtDDqc5HETVE2+k1pb+88ZSydA/HBU=";
    };
  };

  source =
    sources.${stdenv.hostPlatform.system}
      or (throw "Unsupported system for ${pname}: ${stdenv.hostPlatform.system}");
in
stdenv.mkDerivation {
  inherit pname version;

  src = fetchurl {
    url = "https://github.com/steipete/CodexBar/releases/download/v${version}/CodexBarCLI-v${version}-linux-${source.arch}.tar.gz";
    hash = source.hash;
  };

  nativeBuildInputs = [ autoPatchelfHook ];

  sourceRoot = ".";

  buildInputs = with pkgs; [
    curl
    sqlite
    stdenv.cc.cc.lib
  ];

  dontConfigure = true;
  dontBuild = true;

  installPhase = ''
    runHook preInstall

    install -Dm755 CodexBarCLI "$out/bin/CodexBarCLI"
    ln -s CodexBarCLI "$out/bin/codexbar"
    install -Dm644 VERSION "$out/share/${pname}/VERSION"

    runHook postInstall
  '';

  meta = with lib; {
    description = "CLI for CodexBar, an AI coding-provider limits monitor";
    homepage = "https://github.com/steipete/CodexBar";
    license = licenses.mit;
    mainProgram = "codexbar";
    platforms = builtins.attrNames sources;
    sourceProvenance = [ sourceTypes.binaryNativeCode ];
  };
}
