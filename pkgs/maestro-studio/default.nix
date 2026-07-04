{
  lib,
  fetchurl,
  appimageTools,
}:

let
  pname = "maestro-studio";
  version = "unstable-2026-07-04";

  src = fetchurl {
    url = "https://studio.maestro.dev/MaestroStudio.AppImage";
    hash = "sha256-/peSlEt6+OoESVReTL+refh1hyagfkLhzbA0hMZwrPg=";
  };
in
appimageTools.wrapType2 {
  inherit pname version src;

  meta = {
    description = "Visual desktop app for creating and debugging Maestro tests";
    homepage = "https://docs.maestro.dev/maestro-studio";
    license = lib.licenses.unfree;
    mainProgram = "maestro-studio";
    platforms = [ "x86_64-linux" ];
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
  };
}
