# Astal/AGS (GTK4) status bar for epsilon — the primary bar (replaces eww).
#
# Bundles the TSX source in ./src into a self-contained `epsilon-bar` executable
# via the AGS CLI (`ags bundle`). The bar autostarts on the graphical session
# via a systemd user service (default edge "top") and is also kept in
# home.packages so `epsilon-bar` can still be launched by hand for experimenting
# with BAR_EDGE. It is a single-instance app, so the service and a manual run
# cannot coexist — at login the service owns the instance.
{
  pkgs,
  inputs,
  ...
}:
let
  system = pkgs.stdenv.hostPlatform.system;

  agsPackage = inputs.ags.packages.${system}.default;
  astalPkgs = inputs.astal.packages.${system};

  epsilon-bar = pkgs.stdenv.mkDerivation {
    pname = "epsilon-bar";
    version = "0.1";

    src = ./src;

    nativeBuildInputs = [
      agsPackage
      pkgs.wrapGAppsHook3
      pkgs.gobject-introspection
    ];

    buildInputs = [
      pkgs.glib
      pkgs.gjs
      pkgs.typescript
      pkgs.gtk4
      pkgs.gtk4-layer-shell
      astalPkgs.io
      astalPkgs.astal4
      astalPkgs.battery
      astalPkgs.wireplumber
      astalPkgs.network
      astalPkgs.bluetooth
      astalPkgs.tray
      astalPkgs.mpris
      astalPkgs.hyprland
      astalPkgs.notifd
      astalPkgs.cava
    ];

    installPhase = ''
      mkdir -p $out/bin
      ags bundle app.ts $out/bin/epsilon-bar
    '';

    # brightnessctl is invoked at runtime for the brightness widget (Astal has
    # no brightness service).
    preFixup = ''
      gappsWrapperArgs+=(
        --prefix PATH : ${pkgs.lib.makeBinPath [ pkgs.brightnessctl ]}
      )
    '';
  };
in
{
  home.packages = [ epsilon-bar ];

  # Autostart the bar on the graphical session. Modeled after the voxtype
  # service: the layer-shell surface needs WAYLAND_DISPLAY, which Hyprland
  # imports into the systemd user environment on startup.
  systemd.user.services.epsilon-bar = {
    Unit = {
      Description = "Epsilon Astal status bar";
      PartOf = [ "graphical-session.target" ];
      After = [ "graphical-session.target" ];
    };

    Service = {
      ExecStart = "${epsilon-bar}/bin/epsilon-bar";
      Restart = "on-failure";
    };

    Install.WantedBy = [ "graphical-session.target" ];
  };
}
