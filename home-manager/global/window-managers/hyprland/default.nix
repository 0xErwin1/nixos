{ inputs, ... }:
let
  bind = import ./bind.nix;
  rules = import ./rules.nix;
in
{
  imports = [
    ./dependencies.nix
  ];

  xdg.configFile."hypr/eww" = {
    source = ./eww;
    recursive = true;
  };

  wayland.windowManager.hyprland = {
    enable = true;
    xwayland.enable = true;

    plugins = [ ];

    settings = {
      xwayland = {
        force_zero_scaling = true;
      };

      env = [
        "XCURSOR_SIZE,24"
        "HYPRCURSOR_SIZE,24"
        "XDG_CURRENT_DESKTOP,Hyprland"
        "XDG_SESSION_DESKTOP,Hyprland"
        "XDG_SESSION_TYPE,wayland"
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

      "exec-once" = [
        "nm-applet &"
        "blueman-adapters &"
        "udiskie -t &"
        "solaar -b regular -w hide &"
        "gammastep -O 4000 &"
        "tmux setenv -g HYPRLAND_INSTANCE_SIGNATURE \"$HYPRLAND_INSTANCE_SIGNATURE\""
        "eww -c \"$HOME/.config/hypr/eww\" --force-wayland open laptop"
        "hyprpaper -n"
        "dbus-update-activation-environment --systemd --all"
      ];

      general = {
        gaps_in = 5;
        gaps_out = 15;
        border_size = 2;
        resize_on_border = false;
        layout = "dwindle";

        "col.active_border" = "rgb(39bae6)";
        "col.inactive_border" = "rgb(c2d94c)";

        allow_tearing = false;
      };

      animations = {
        enabled = true;
        bezier = [ "snappy, 0.4, 0.02, 0.6, 0.95" ];
        animation = [
          "global, 1, 0.7, snappy"
          "windows, 1, 0.7, snappy"
          "fade, 1, 0.7, snappy"
          "workspaces, 0.7, 4, snappy"
        ];
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

      dwindle = {
        pseudotile = false;
        preserve_split = true;
      };

      master = {
        new_status = "master";
      };

      misc = {
        force_default_wallpaper = 1;
        disable_hyprland_logo = false;
      };

      # Input/gestures
      input = {
        kb_layout = "us";
        kb_variant = "";
        kb_model = "";
        kb_options = "ctrl:nocaps";
        kb_rules = "";

        follow_mouse = 1;
        sensitivity = 0;

        touchpad = {
          natural_scroll = false;
        };
      };

      gestures = {
        workspace_swipe = false;
      };

      device = [
        {
          name = "tpps/2-elan-trackpoint";
          sensitivity = -0.5;
        }
      ];

      "$mod" = "SUPER";
      "$terminal" = "alacritty";
      "$fileManager" = "pcmanfm";
      "$menu" = "wofi --show drun";
      "$menuWindow" = "wofi -show window";
      "$browser" = "zen-browser";
      "$workBrowser" = "firefox";
      "$screenshot" = ''grim -g "$(slurp)" - | swappy -f -'';

      inherit (bind) bind;
      inherit (bind) bindel;
      inherit (bind) bindm;
      inherit (bind) bindl;

      inherit (rules) windowrulev2;
      inherit (rules) windowrulev1;
    };
  };
}
