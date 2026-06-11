{ pkgs }:

let
  inherit (pkgs)
    lib
    stdenvNoCC
    fetchurl
    makeWrapper
    nodejs
    ;

  pname = "ccstatusline";
  version = "2.2.19";
in
stdenvNoCC.mkDerivation {
  inherit pname version;

  src = fetchurl {
    url = "https://registry.npmjs.org/ccstatusline/-/ccstatusline-${version}.tgz";
    hash = "sha256-ZECyfJStzolhs1EQrrbq6svXCtvcpj6YJRPjFIazLSw=";
  };

  nativeBuildInputs = [ makeWrapper ];

  installPhase = ''
    runHook preInstall

    install -Dm644 dist/ccstatusline.js "$out/lib/ccstatusline/ccstatusline.js"

    makeWrapper "${nodejs}/bin/node" "$out/bin/ccstatusline" \
      --add-flags "$out/lib/ccstatusline/ccstatusline.js"

    runHook postInstall
  '';

  meta = with lib; {
    description = "Status line formatter for Claude Code (bundled npm release)";
    homepage = "https://github.com/sirmalloc/ccstatusline";
    license = licenses.mit;
    mainProgram = "ccstatusline";
    platforms = platforms.linux;
  };
}
