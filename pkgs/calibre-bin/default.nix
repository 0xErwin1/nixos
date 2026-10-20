{ pkgs }:

let
  inherit (pkgs)
    lib
    stdenv
    fetchurl
    makeDesktopItem
    writeShellScript
    ;

  pname = "calibre-bin";
  version = "9.16.0";

  sources = {
    x86_64-linux = {
      arch = "x86_64";
      hash = "sha256-A81P2kPeI9ZUBaPJC5JLxKXIR1PjiFidTKND2bpWGh0=";
    };

    aarch64-linux = {
      arch = "arm64";
      hash = "sha256-gr9d6BmmVfwMi3idOI/vU8RYP5wvm4OhTfQnJFGaGX0=";
    };
  };

  source =
    sources.${stdenv.hostPlatform.system}
      or (throw "Unsupported system for ${pname}: ${stdenv.hostPlatform.system}");

  programs = [
    "calibre"
    "calibredb"
    "calibre-debug"
    "calibre-server"
    "ebook-convert"
    "ebook-edit"
    "ebook-meta"
    "ebook-polish"
    "ebook-viewer"
    "fetch-ebook-metadata"
  ];

  # The upstream bundle ships its own Python, Qt and QtWebEngine and resolves
  # them relative to its launchers. Keep it untouched and run it inside an FHS
  # environment that provides the system libraries it expects.
  rawPackage = stdenv.mkDerivation {
    pname = "${pname}-bundle";
    inherit version;

    src = fetchurl {
      url = "https://download.calibre-ebook.com/${version}/calibre-${version}-${source.arch}.txz";
      inherit (source) hash;
    };

    sourceRoot = ".";
    dontConfigure = true;
    dontBuild = true;
    dontPatchELF = true;
    dontStrip = true;

    installPhase = ''
      runHook preInstall
      mkdir -p "$out/opt"
      cp -a . "$out/opt/calibre"
      runHook postInstall
    '';
  };

  bundleDir = "${rawPackage}/opt/calibre";

  # The FHS env runs this with the bundle program as its first argument.
  dispatcher = writeShellScript "calibre-dispatch" ''
    program="$1"
    shift
    exec "${bundleDir}/$program" "$@"
  '';

  fhsEnv = pkgs.buildFHSEnv {
    name = "${pname}-fhs-${version}";

    targetPkgs =
      pkgs: with pkgs; [
        stdenv.cc.cc.lib
        glibc
        zlib
        expat
        fontconfig
        freetype
        glib
        dbus
        nss
        nspr
        alsa-lib
        libpulseaudio
        libGL
        libdrm
        libgbm
        mesa
        libxkbcommon
        wayland
        krb5
        cups
        libxkbfile
        pcre2
        systemd
        util-linux
        libinput
        mtdev
        ncurses
        flite
        speechd-minimal
        xorg.libSM
        xorg.libICE
        xorg.libX11
        xorg.libXext
        xorg.libXrender
        xorg.libXi
        xorg.libXfixes
        xorg.libXrandr
        xorg.libXcomposite
        xorg.libXdamage
        xorg.libXcursor
        xorg.libXtst
        xorg.libxshmfence
        xorg.libxcb
        xorg.xcbutil
        xorg.xcbutilwm
        xorg.xcbutilimage
        xorg.xcbutilkeysyms
        xorg.xcbutilrenderutil
        xorg.xcbutilcursor
      ];

    runScript = dispatcher;
  };

  desktopItems = [
    (makeDesktopItem {
      name = "calibre-gui";
      desktopName = "calibre";
      genericName = "E-book library management";
      comment = "E-book library management: Convert, view, share, catalogue all your e-books";
      exec = "calibre --detach %U";
      icon = "calibre-gui";
      categories = [ "Office" ];
    })
    (makeDesktopItem {
      name = "calibre-ebook-viewer";
      desktopName = "E-book viewer";
      genericName = "Viewer for E-books";
      comment = "Viewer for E-books in all the major formats";
      exec = "ebook-viewer --detach %f";
      icon = "calibre-viewer";
      categories = [ "Office" "Viewer" ];
      mimeTypes = [
        "application/epub+zip"
        "application/x-mobipocket-ebook"
        "application/vnd.amazon.ebook"
        "application/x-cbz"
        "application/x-cbr"
        "application/x-fictionbook+xml"
        "application/pdf"
      ];
    })
    (makeDesktopItem {
      name = "calibre-ebook-edit";
      desktopName = "E-book editor";
      genericName = "Editor for E-books";
      comment = "Edit E-books in various formats";
      exec = "ebook-edit --detach %f";
      icon = "calibre-ebook-edit";
      categories = [ "Office" ];
      mimeTypes = [
        "application/epub+zip"
        "application/x-mobipocket-ebook"
        "application/vnd.amazon.ebook"
      ];
    })
  ];
in
stdenv.mkDerivation {
  inherit pname version;

  dontUnpack = true;
  dontConfigure = true;
  dontBuild = true;

  installPhase = ''
    runHook preInstall

    mkdir -p "$out/bin"
    for program in ${lib.escapeShellArgs programs}; do
      cat > "$out/bin/$program" <<EOF
    #!${pkgs.runtimeShell}
    exec ${fhsEnv}/bin/${fhsEnv.name} $program "\$@"
    EOF
      chmod +x "$out/bin/$program"
    done

    images="${bundleDir}/resources/images"
    install -Dm644 "$images/lt.png" "$out/share/icons/hicolor/256x256/apps/calibre-gui.png"
    install -Dm644 "$images/viewer.png" "$out/share/icons/hicolor/256x256/apps/calibre-viewer.png"
    install -Dm644 "$images/tweak.png" "$out/share/icons/hicolor/256x256/apps/calibre-ebook-edit.png"

    mkdir -p "$out/share/applications"
    for item in ${lib.concatMapStringsSep " " (item: "${item}/share/applications/*.desktop") desktopItems}; do
      ln -s "$item" "$out/share/applications/"
    done

    runHook postInstall
  '';

  meta = with lib; {
    description = "Comprehensive e-book software (official upstream binary bundle)";
    homepage = "https://calibre-ebook.com";
    license = licenses.gpl3Only;
    mainProgram = "calibre";
    platforms = builtins.attrNames sources;
    sourceProvenance = [ sourceTypes.binaryNativeCode ];
  };
}
