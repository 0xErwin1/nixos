{ inputs, ... }:
let
  bind = import ./bind.nix;
  rules = import ./rules.nix;
in
{
  imports = [
    ./dependencies.nix
  ];

  wayland.windowManager.hyprland = {
    enable = true;
    xwayland.enable = true;

    plugins = [
      inputs.pyprland.packages.x86_64-linux.default
    ];

    settings = {
      env = [
        "XCURSOR_SIZE, 24"
        "XDG_CURRENT_DESKTOP, Hyprland"
        "XDG_SESSION_TYPE, wayland"
        "XDG_SESSION_DESKTOP, Hyprland "
        "QT_QPA_PLATFORM, wayland;xcb"
        "QT_WAYLAND_DISABLE_WINDOWDECORATION, 1"
        "QT_AUTO_SCREEN_SCALE_FACTOR, 0"
        "QT_QPA_PLATFORMTHEME, qt6ct"
        "ELECTRON_OZONE_PLATFORM_HINT, auto"
        "MOZ_ENABLE_WAYLAND, 1"
      ];
      monitor = ",preferred,auto,auto";

      general = {
        gaps_in = 5;
        gaps_out = 20;
        border_size = 2;
        resize_on_border = true;
        layout = "dwindle";

        allow_tearing = false;
      };

      animations = {
        enabled = false;
      };

      decoration = {
        rounding = 5;
        blur = {
          enabled = false;
          size = 3;
          passes = 1;
        };

        drop_shadow = true;
        shadow_range = 50;
        shadow_render_power = 9;
      };

      "$mod" = "SUPER";
      "$terminal" = "kitty";
      "$browser" = "librewolf";
      "$workBrowser" = "firefox-developer-edition";

      inherit (bind) bind;
      inherit (bind) bindel;
      inherit (bind) bindm;

      inherit (rules) windowrulev2;
      inherit (rules) windowrulev1;
    };
  };
}
