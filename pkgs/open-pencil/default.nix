{
  lib,
  stdenv,
  fetchurl,
  dpkg,
  autoPatchelfHook,
  wrapGAppsHook3,
  webkitgtk_4_1,
  gtk3,
  libsoup_3,
  glib,
  cairo,
  gdk-pixbuf,
  fontconfig,
  dbus,
  glib-networking,
  xdg-utils,
  desktop-file-utils,
  open-pencil-mcp,
}:

stdenv.mkDerivation rec {
  pname = "open-pencil";
  version = "0.15.1";

  src = fetchurl {
    url = "https://github.com/open-pencil/open-pencil/releases/download/v${version}/OpenPencil_${version}_amd64.deb";
    hash = "sha256-IP6tQoFbbSp4VLaIkTvsu6Xhzip++yxuCg4jQAFFcfg=";
  };

  nativeBuildInputs = [
    dpkg
    autoPatchelfHook
    wrapGAppsHook3
  ];

  buildInputs = [
    webkitgtk_4_1
    gtk3
    libsoup_3
    glib
    cairo
    gdk-pixbuf
    fontconfig
    dbus
    glib-networking
    stdenv.cc.cc.lib
  ];

  # The Tauri deep-link plugin registers openpencil:// through xdg-utils and
  # desktop-file-utils, and the app spawns its MCP server from PATH.
  # The session-wide GDK_DPI_SCALE shrinks the WebKitGTK interface, so this
  # app is pinned to the unscaled value.
  preFixup = ''
    gappsWrapperArgs+=(
      --prefix PATH : ${
        lib.makeBinPath [
          xdg-utils
          desktop-file-utils
          open-pencil-mcp
        ]
      }
      --set GDK_DPI_SCALE 1
    )
  '';

  unpackPhase = ''
    runHook preUnpack
    dpkg-deb -x $src .
    runHook postUnpack
  '';

  installPhase = ''
    runHook preInstall
    mkdir -p $out
    cp -r usr/* $out/
    ln -s $out/bin/OpenPencil $out/bin/open-pencil
    runHook postInstall
  '';

  meta = {
    description = "AI-native, Figma-compatible open-source design editor";
    homepage = "https://openpencil.dev";
    license = lib.licenses.mit;
    mainProgram = "OpenPencil";
    platforms = [ "x86_64-linux" ];
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
  };
}
