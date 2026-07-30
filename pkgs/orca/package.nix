{
  lib,
  fetchurl,
  appimageTools,
}:

let
  pname = "orca";
  version = "1.4.162";

  src = fetchurl {
    url = "https://github.com/stablyai/orca/releases/download/v${version}/orca-linux.AppImage";
    hash = "sha256-DyjfaYs974d+aK3KKIamR39SMD3SEVBagIBdPgFaacQ=";
  };
in
appimageTools.wrapType2 {
  inherit pname version src;

  extraInstallCommands =
    let
      contents = appimageTools.extract { inherit pname version src; };
    in
    ''
      install -m 444 -D ${contents}/orca-ide.desktop -t $out/share/applications
      substituteInPlace $out/share/applications/orca-ide.desktop \
        --replace 'Exec=AppRun' 'Exec=${pname}'
      cp -r ${contents}/usr/share/icons $out/share
    '';

  meta = {
    description = "Next-generation IDE for parallel agentic development";
    homepage = "https://github.com/stablyai/orca";
    license = lib.licenses.mit;
    mainProgram = pname;
    platforms = [ "x86_64-linux" ];
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
  };
}
