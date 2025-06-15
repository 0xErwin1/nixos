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

    plugins = [ ];

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
      ecosystem = {
        enforce_permissions = true;
      };

      permissions = [
        "/usr/(bin|local/bin)/grim, screencopy, allow"
        "/usr/(lib|libexec|lib64)/xdg-desktop-portal-hyprland, screencopy, allow"
        "/usr/(bin|local/bin)/hyprpm, plugin, allow"
      ];
      monitor = ",preferred,auto,1";

      general = {
        gaps_in = 5;
        gaps_out = 20;
        border_size = 2;
        resize_on_border = true;
        layout = "dwindle";

        "col.active_border" = "rgb(39bae6)";
        "col.inactive_border" = "rgb(c2d94c)";

        allow_tearing = false;
      };

      animations = {
        enabled = true;
        bezier = "0.25, 0.1, 0.25, 1.0";
      };

      decoration = {
        rounding = 10;
        rounding_power = 2;
        active_opacity = 1.0;
        inactive_opacity = 1.0;

        shadow = {
          enabled = true;
          range = 4;
          render_power = 3;
        };

        blur = {
          enabled = true;
          size = 3;
          passes = 1;

          vibrancy = 0.1696;
        };
      };

      "$mod" = "SUPER";
      "$terminal" = "alacritty";
      "$browser" = "zen-browser";
      "$workBrowser" = "firefox";
      "$screenshot" = ''grim -g "$(slurp)" - | swappy -f -'';

      inherit (bind) bind;
      inherit (bind) bindel;
      inherit (bind) bindm;

      inherit (rules) windowrulev2;
      inherit (rules) windowrulev1;
    };
  };
}
