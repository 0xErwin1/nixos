{ pkgs }:

let
  inherit (pkgs) lib;

  pname = "codex-desktop";
  version = "2026.05.01";

  src = pkgs.fetchFromGitHub {
    owner = "ilysenko";
    repo = "codex-desktop-linux";
    rev = "2a62e7fc2b97ab148c986cc7c5daa8a5ac378c29";
    hash = "sha256-tR7A4FWn/h2T6aHLjyU7r9wwYIIoVlKuEO/rQl1TBL8=";
  };

  codexDmg = pkgs.fetchurl {
    url = "https://persistent.oaistatic.com/codex-app-prod/Codex.dmg";
    hash = "sha256-qd0LCxoFaG7R8AksuxMldzhZ3t91qzGzXKRmVrK5LLY=";
  };

  electronLibs = with pkgs; [
    glib
    gtk3
    pango
    cairo
    gdk-pixbuf
    atk
    at-spi2-atk
    at-spi2-core
    nss
    nspr
    dbus
    cups
    expat
    libdrm
    mesa
    libgbm
    alsa-lib
    libX11
    libXcomposite
    libXdamage
    libXext
    libXfixes
    libXrandr
    libxcb
    libxkbcommon
    libxcursor
    libxi
    libxtst
    libxscrnsaver
    libglvnd
    systemd
    wayland
  ];

  runtimeInputs = with pkgs; [
    bash
    nodejs
    python3
    p7zip
    curl
    unzip
    gnumake
    gcc
    patchelf
    coreutils
    findutils
    gawk
    gnugrep
    gnused
    procps
    xdg-utils
    libnotify
  ];

  electronLibPath = lib.makeLibraryPath electronLibs;
in
pkgs.stdenvNoCC.mkDerivation {
  inherit pname version;

  dontUnpack = true;
  dontBuild = true;
  dontFixup = true;

  installPhase = ''
        mkdir -p $out/bin $out/share/applications $out/share/icons/hicolor/256x256/apps

        cat > $out/bin/${pname} <<'EOF'
    #!${pkgs.bash}/bin/bash
    set -euo pipefail

    export PATH=${lib.makeBinPath runtimeInputs}:$PATH

    state_root="''${XDG_DATA_HOME:-$HOME/.local/share}/codex-desktop-linux"
    source_dir="$state_root/source"
    app_dir="$state_root/codex-app"
    rev_file="$state_root/source-rev"
    expected_rev="${src.rev}"

    install_or_update_app() {
      workdir="$(mktemp -d)"
      cleanup() {
        rm -rf "$workdir"
      }
      trap cleanup RETURN

      mkdir -p "$source_dir" "$app_dir"
      rm -rf "$source_dir"
      mkdir -p "$source_dir"

      cp -R ${src}/. "$source_dir"
      chmod -R u+w "$source_dir"
      cp ${codexDmg} "$source_dir/Codex.dmg"
      chmod +x "$source_dir/install.sh"

      cd "$source_dir"
      CODEX_INSTALL_DIR="$app_dir" \
        ${pkgs.bash}/bin/bash "$source_dir/install.sh" "$source_dir/Codex.dmg"

      if [ -f "$app_dir/electron" ]; then
        patchelf \
          --set-interpreter "$(cat ${pkgs.stdenv.cc}/nix-support/dynamic-linker)" \
          --set-rpath "$app_dir:${electronLibPath}" \
          "$app_dir/electron"

        if [ -f "$app_dir/chrome_crashpad_handler" ]; then
          patchelf \
            --set-interpreter "$(cat ${pkgs.stdenv.cc}/nix-support/dynamic-linker)" \
            "$app_dir/chrome_crashpad_handler" || true
        fi

        if [ -f "$app_dir/chrome-sandbox" ]; then
          patchelf \
            --set-interpreter "$(cat ${pkgs.stdenv.cc}/nix-support/dynamic-linker)" \
            "$app_dir/chrome-sandbox" || true
        fi

        find "$app_dir" -maxdepth 1 -name "*.so*" -type f | while read -r so; do
          patchelf --set-rpath "${electronLibPath}" "$so" 2>/dev/null || true
        done
      fi

      printf '%s\n' "$expected_rev" > "$rev_file"
    }

    if [ "''${1:-}" = "--rebuild" ]; then
      rm -rf "$app_dir" "$source_dir" "$rev_file"
      shift
    fi

    if [ ! -x "$app_dir/start.sh" ] || [ ! -f "$rev_file" ] || [ "$(cat "$rev_file")" != "$expected_rev" ]; then
      install_or_update_app
    fi

    exec "$app_dir/start.sh" "$@"
    EOF
        chmod +x $out/bin/${pname}

        cat > $out/share/applications/${pname}.desktop <<EOF
    [Desktop Entry]
    Name=Codex Desktop
    Comment=OpenAI Codex Desktop for Linux
    Exec=$out/bin/${pname}
    Icon=${pname}
    Type=Application
    Categories=Development;IDE;
    StartupWMClass=codex-desktop
    EOF

        cp ${src}/assets/codex.png $out/share/icons/hicolor/256x256/apps/${pname}.png
  '';

  meta = with lib; {
    description = "OpenAI Codex Desktop for Linux";
    homepage = "https://github.com/ilysenko/codex-desktop-linux";
    mainProgram = pname;
    platforms = [ "x86_64-linux" ];
    sourceProvenance = [ sourceTypes.binaryNativeCode ];
  };
}
