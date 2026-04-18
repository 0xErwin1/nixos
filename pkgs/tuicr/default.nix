{ pkgs }:

let
  inherit (pkgs) lib stdenvNoCC fetchurl;

  sources = {
    x86_64-linux = {
      target = "x86_64-unknown-linux-gnu";
      hash = "sha256-Is1mumqnuBbA48fyQWGRs5kCOFPdKvCO3zDNBAD63I4=";
    };

    aarch64-linux = {
      target = "aarch64-unknown-linux-gnu";
      hash = "sha256-dS2WtMhP0WRRSEsWWwuAtHqM98C1axh98WqX3nOn+Cs=";
    };

    x86_64-darwin = {
      target = "x86_64-apple-darwin";
      hash = "sha256-J/pq8Oq4mmo+p7VNY12o95aQDyMpxdsD4E7a03UAQss=";
    };

    aarch64-darwin = {
      target = "aarch64-apple-darwin";
      hash = "sha256-2jeY/+bjjcHs4WuM6EL81g0Ns+gMgMMmuRJkQg1a9jQ=";
    };
  };

  source =
    sources.${pkgs.stdenv.hostPlatform.system}
      or (throw "Unsupported system for tuicr: ${pkgs.stdenv.hostPlatform.system}");
in
stdenvNoCC.mkDerivation rec {
  pname = "tuicr";
  version = "0.10.0";

  dontUnpack = true;

  src = fetchurl {
    url = "https://github.com/agavra/tuicr/releases/download/v${version}/${pname}-${version}-${source.target}.tar.gz";
    sha256 = source.hash;
  };

  installPhase = ''
    runHook preInstall

    tar -xzf "$src"
    install -Dm755 tuicr $out/bin/tuicr

    runHook postInstall
  '';

  meta = with lib; {
    description = "Terminal UI for local code review";
    homepage = "https://github.com/agavra/tuicr";
    license = licenses.mit;
    mainProgram = "tuicr";
    platforms = builtins.attrNames sources;
    sourceProvenance = [ sourceTypes.binaryNativeCode ];
  };
}
