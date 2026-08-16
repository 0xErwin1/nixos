# Astal/AGS (GTK4) status bar shared across hosts — the primary bar (replaces
# eww).
#
# Bundles the TSX source in ./src into a self-contained `wl-bar` executable via
# the AGS CLI (`ags bundle`). The bar autostarts on the graphical session via a
# systemd user service (default edge "top") and is also kept in home.packages so
# `wl-bar` can still be launched by hand for experimenting with BAR_EDGE. It is a
# single-instance app, so the service and a manual run cannot coexist — at login
# the service owns the instance.
{
  pkgs,
  inputs,
  ...
}:
let
  system = pkgs.stdenv.hostPlatform.system;

  agsPackage = inputs.ags.packages.${system}.default;
  astalPkgs = inputs.astal.packages.${system};

  # Provider-agnostic AI usage fetcher (Claude + Codex + Grok + Kimi) for the
  # "extras" panel, written in Brasa. `writeBrasaProject` reads the entry out
  # of the project's own `brasa.toml` and bundles it, so the type check and
  # the whole compiler gate the build: a program that does not compile can
  # never reach an activated generation.
  #
  # No SSL_CERT_FILE wrapper, unlike the Go command this replaces: Brasa's
  # `std::http` is ureq with rustls and webpki-roots, so the CA bundle is
  # compiled into the binary and TLS does not consult the environment.
  # Verified by running it with `env -i` and watching all four providers
  # answer.
  brasaPkgs = inputs.brasa.overlays.default pkgs pkgs;

  ai-usage-wrapped = brasaPkgs.writeBrasaProject {
    src = ./ai-usage;
    name = "epsilon-ai-usage";
  };

  wl-bar = pkgs.stdenv.mkDerivation {
    pname = "wl-bar";
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
      # AstalNetwork does not model VPN tunnels, so the network module reads
      # NM.Client's active connections directly. astal-network does not propagate
      # the NM typelib, so it has to be pulled in explicitly for `gi://NM`.
      pkgs.networkmanager
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
      ags bundle app.ts $out/bin/wl-bar
    '';

    # Runtime CLIs the bar shells out to: brightnessctl (brightness widget, no
    # Astal service), pactl (bluetooth A2DP/HFP profile switching — wpctl does
    # not cleanly enumerate bluez card profiles, and pactl is otherwise absent on
    # this host), curl (Open-Meteo weather + geocoding), khal (calendar events
    # for the calendar panel), epsilon-ai-usage (AI usage for the extras panel)
    # and notify-send (AI-usage threshold/reset alerts, delivered to our own
    # notifd).
    preFixup = ''
      gappsWrapperArgs+=(
        --prefix PATH : ${
          pkgs.lib.makeBinPath [
            pkgs.brightnessctl
            pkgs.pulseaudio
            pkgs.wireplumber
            pkgs.curl
            pkgs.khal
            pkgs.libnotify
            ai-usage-wrapped
          ]
        }
      )
    '';
  };
in
{
  home.packages = [
    wl-bar
    ai-usage-wrapped
  ];

  # Autostart the bar on the graphical session. Modeled after the voxtype
  # service: the layer-shell surface needs WAYLAND_DISPLAY, which Hyprland
  # imports into the systemd user environment on startup.
  systemd.user.services.wl-bar = {
    Unit = {
      Description = "Wayland Astal status bar";
      PartOf = [ "graphical-session.target" ];
      After = [ "graphical-session.target" ];
    };

    Service = {
      ExecStart = "${wl-bar}/bin/wl-bar";
      Restart = "on-failure";
    };

    Install.WantedBy = [ "graphical-session.target" ];
  };
}
