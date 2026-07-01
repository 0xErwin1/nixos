{ pkgs }:

let
  inherit (pkgs)
    lib
    stdenv
    fetchurl
    makeWrapper
    autoPatchelfHook
    wrapGAppsHook3
    copyDesktopItems
    makeDesktopItem
    xdg-utils
    coreutils
    ;

  pname = "claude-desktop";
  version = "1.17377.1";

  sources = {
    x86_64-linux = {
      arch = "amd64";
      hash = "sha256-9L14VFIAh3tZEXmDjeeteld99u0uhFlp3SVpDvxchcc=";
    };

    aarch64-linux = {
      arch = "arm64";
      hash = "sha256-ZYrL/xS9nDXXle3kbwl/ynnUM6xK95LN1khqzTrcby4=";
    };
  };

  source =
    sources.${stdenv.hostPlatform.system}
      or (throw "Unsupported system for ${pname}: ${stdenv.hostPlatform.system}");

  runtimeLibs = with pkgs; [
    alsa-lib
    at-spi2-atk
    at-spi2-core
    atk
    cairo
    cups
    dbus
    expat
    fontconfig
    freetype
    gdk-pixbuf
    glib
    gtk3
    libdrm
    libgbm
    libcap_ng
    libnotify
    libseccomp
    libsecret
    libuuid
    nspr
    nss
    pango
    stdenv.cc.cc.lib
    systemd
    wayland
    libx11
    libxcb
    libxcomposite
    libxdamage
    libxext
    libxfixes
    libxi
    libxkbcommon
    libxrandr
    libxrender
    libxshmfence
    libxtst
  ];

  runtimeBins = with pkgs; [
    coreutils
    glib
    trash-cli
    xdg-utils
  ];
in
stdenv.mkDerivation {
  inherit pname version;

  src = fetchurl {
    url = "https://downloads.claude.ai/claude-desktop/apt/stable/pool/main/c/claude-desktop/claude-desktop_${version}_${source.arch}.deb";
    hash = source.hash;
  };

  nativeBuildInputs = [
    autoPatchelfHook
    copyDesktopItems
    makeWrapper
    wrapGAppsHook3
  ];

  buildInputs = runtimeLibs;

  dontUnpack = true;
  dontConfigure = true;
  dontBuild = true;

  installPhase = ''
    runHook preInstall

    mkdir -p "$out" deb
    cd deb
    ar x "$src"
    tar -xJf data.tar.xz --no-same-owner --no-same-permissions -C "$out"
    cd ..

    chmod 0755 "$out/usr/lib/${pname}/chrome-sandbox"

    mkdir -p "$out/bin"
    rm -f "$out/bin/${pname}"

    runHook postInstall
  '';

  desktopItems = [
    (makeDesktopItem {
      name = pname;
      desktopName = "Claude";
      genericName = "AI Assistant";
      comment = "Desktop application for Claude.ai";
      exec = "${pname} %U";
      icon = pname;
      type = "Application";
      startupNotify = true;
      startupWMClass = pname;
      categories = [
        "Utility"
        "Development"
      ];
      mimeTypes = [ "x-scheme-handler/claude" ];
      keywords = [
        "AI"
        "Chat"
        "Assistant"
        "Claude"
        "Code"
        "LLM"
      ];
      extraConfig = {
        SingleMainWindow = "true";
      };
    })
  ];

  preFixup = ''
    gappsWrapperArgs+=(
      --prefix LD_LIBRARY_PATH : ${lib.makeLibraryPath runtimeLibs}
      --prefix PATH : ${lib.makeBinPath runtimeBins}
      --add-flags --no-sandbox
    )
  '';

  postFixup = ''
    makeWrapper "$out/usr/lib/${pname}/${pname}" "$out/bin/${pname}" "''${gappsWrapperArgs[@]}"
  '';

  meta = with lib; {
    description = "Official Claude desktop app for Linux";
    homepage = "https://code.claude.com/docs/en/desktop-linux";
    license = licenses.unfree;
    mainProgram = pname;
    platforms = builtins.attrNames sources;
    sourceProvenance = [ sourceTypes.binaryNativeCode ];
  };
}
