{ pkgs }:

let
  inherit (pkgs)
    lib
    stdenv
    fetchurl
    dpkg
    wrapGAppsHook3
    adwaita-icon-theme
    gsettings-desktop-schemas
    glib
    gtk3
    gtk4
    xdg-utils
    coreutils
    libGL
    qt6
    patchelf
    ;

  pname = "brave-origin-nightly";
  version = "1.91.68";

  commandLineArgs = "--ozone-platform=wayland --disable-features=OutdatedBuildDetector,Vulkan";

  sources = {
    x86_64-linux = {
      target = "amd64";
      hash = "sha256-fbUNFA+RpYVcse5pd7ppcBj2x2L0axIxVNzXhrd76ds=";
    };

    aarch64-linux = {
      target = "arm64";
      hash = "sha256-4oSdxuybPP/7NXWtdHcIZxJv20Qoi5ePHfGZGDtIIgA=";
    };
  };

  source =
    sources.${pkgs.stdenv.hostPlatform.system}
      or (throw "Unsupported system for ${pname}: ${pkgs.stdenv.hostPlatform.system}");

  deps = with pkgs; [
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
    gtk4
    libdrm
    libgbm
    libGL
    libkrb5
    libnotify
    libuuid
    nspr
    nss
    pango
    pipewire
    qt6.qtbase
    snappy
    stdenv.cc.cc.lib
    udev
    vulkan-loader
    wayland
    libx11
    libxscrnsaver
    libxcomposite
    libxcursor
    libxdamage
    libxext
    libxfixes
    libxi
    libxrandr
    libxrender
    libxtst
    libxcb
    libxshmfence
    libxkbcommon
    zlib
  ];

  rpath = lib.makeLibraryPath deps + ":" + lib.makeSearchPathOutput "lib" "lib64" deps;
  binpath = lib.makeBinPath deps;
in
stdenv.mkDerivation {
  inherit pname version;

  src = fetchurl {
    url = "https://github.com/brave/brave-browser/releases/download/v${version}/${pname}_${version}_${source.target}.deb";
    sha256 = source.hash;
  };

  dontUnpack = true;
  dontConfigure = true;
  dontBuild = true;
  dontPatchELF = true;

  nativeBuildInputs = [
    dpkg
    patchelf
    wrapGAppsHook3
  ];

  buildInputs = [
    glib
    gsettings-desktop-schemas
    gtk3
    gtk4
    adwaita-icon-theme
  ];

  preFixup = ''
    gappsWrapperArgs+=(
      --prefix LD_LIBRARY_PATH : ${rpath}
      --prefix PATH : ${binpath}
      --suffix PATH : ${
        lib.makeBinPath [
          xdg-utils
          coreutils
        ]
      }
      --set CHROME_WRAPPER ${pname}
      --add-flags ${lib.escapeShellArg commandLineArgs}
    )
  '';

  installPhase = ''
    runHook preInstall

    mkdir unpacked deb
    cp "$src" deb/package.deb
    ar x deb/package.deb --output deb
    tar -xJf deb/data.tar.xz --no-same-owner --no-same-permissions -C unpacked

    mkdir -p "$out" "$out/bin"

    cp -R unpacked/usr/share "$out"
    cp -R unpacked/opt "$out"

    export BINARYWRAPPER="$out/opt/brave.com/${pname}/${pname}"

    substituteInPlace "$BINARYWRAPPER" \
      --replace-fail /bin/bash ${stdenv.shell} \
      --replace-fail 'CHROME_WRAPPER' 'WRAPPER'

    ln -sf "$BINARYWRAPPER" "$out/bin/${pname}"

    for exe in "$out/opt/brave.com/${pname}/brave" "$out/opt/brave.com/${pname}/chrome_crashpad_handler"; do
      patchelf \
        --set-interpreter "$(cat $NIX_CC/nix-support/dynamic-linker)" \
        --set-rpath "${rpath}" \
        "$exe"
    done

    substituteInPlace "$out/share/applications/brave-origin-nightly.desktop" \
      --replace-fail /usr/bin/${pname} "$out/bin/${pname}"

    substituteInPlace "$out/share/applications/com.brave.Origin.nightly.desktop" \
      --replace-fail /usr/bin/${pname} "$out/bin/${pname}"

    substituteInPlace "$out/share/gnome-control-center/default-apps/${pname}.xml" \
      --replace-fail /opt/brave.com "$out/opt/brave.com"

    substituteInPlace "$out/opt/brave.com/${pname}/default-app-block" \
      --replace-fail /opt/brave.com "$out/opt/brave.com"

    for size in 16 24 32 48 64 128 256; do
      mkdir -p "$out/share/icons/hicolor/''${size}x''${size}/apps"
      ln -s "$out/opt/brave.com/${pname}/product_logo_''${size}.png" \
        "$out/share/icons/hicolor/''${size}x''${size}/apps/${pname}.png"
    done

    ln -sf ${xdg-utils}/bin/xdg-settings "$out/opt/brave.com/${pname}/xdg-settings"
    ln -sf ${xdg-utils}/bin/xdg-mime "$out/opt/brave.com/${pname}/xdg-mime"

    runHook postInstall
  '';

  meta = with lib; {
    description = "Brave Origin browser nightly build";
    homepage = "https://brave.com/origin/linux/nightly/";
    license = licenses.mpl20;
    mainProgram = pname;
    platforms = builtins.attrNames sources;
    sourceProvenance = [ sourceTypes.binaryNativeCode ];
  };
}
