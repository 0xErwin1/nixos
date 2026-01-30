let
  bind = import ./bind.nix;
in
{
  imports = [
    ./dependencies.nix
    ../../wayland/wofi
    ../../wayland/eww
    ./hyprlock.nix
    ./hyprpaper.nix
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
        # Scaling
        "GDK_SCALE,1"
        "GDK_DPI_SCALE,0.8"
        "QT_AUTO_SCREEN_SCALE_FACTOR,1"
        # NVIDIA
        "WLR_NO_HARDWARE_CURSORS,0"
        "WLR_DRM_DEVICES,/dev/dri/card0:/dev/dri/card1"
        "__GLX_VENDOR_LIBRARY_NAME,nvidia"
        "GBM_BACKEND,nvidia-drm"
        "LIBVA_DRIVER_NAME,nvidia"
      ];

      ecosystem = {
        enforce_permissions = true;
      };

      permissions = [
        "/usr/(bin|local/bin)/grim, screencopy, allow"
        "/usr/(lib|libexec|lib64)/xdg-desktop-portal-hyprland, screencopy, allow"
        "/usr/(bin|local/bin)/hyprpm, plugin, allow"
      ];

      monitor = [
        "eDP-1, 1920x1080@60, 0x0, 1"
        "DP-2, 1920x1080@60, 0x1080, 1"
      ];

      "exec-once" = [
        "dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP"
        "dbus-update-activation-environment --systemd --all"
        "systemctl --user import-environment WAYLAND_DISPLAY XDG_CURRENT_DESKTOP"
        "gammastep -O 4000 &"
        "tmux setenv -g HYPRLAND_INSTANCE_SIGNATURE \"$HYPRLAND_INSTANCE_SIGNATURE\""
        "eww -c \"$HOME/.config/hypr/eww\" --force-wayland open-many laptop monitor"
        "nm-applet &"
        "blueman-adapters &"
        "udiskie -t &"
        "solaar -b regular -w hide &"
        "hyprpaper"
        "xdg-desktop-portal &"
        "xdg-desktop-portal-wlr &"
      ];

      general = {
        gaps_in = 0;
        gaps_out = 5;
        border_size = 1;
        resize_on_border = true;
        layout = "dwindle";

        "col.active_border" = "rgb(39bae6)";
        "col.inactive_border" = "rgb(c2d94c)";

        allow_tearing = true;
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
      };

      device = [
        {
          name = "tpps/2-elan-trackpoint";
          sensitivity = -0.5;
        }
      ];

      "$mod" = "SUPER";
      "$terminal" = "ghostty";
      "$fileManager" = "pcmanfm";
      "$menu" = "wofi --show drun";
      "$menuWindow" = "wofi -show window";
      "$browser" = "zen-browser";
      "$workBrowser" = "firefox";
      "$screenshot" = "hyprshot -m region --raw | satty --filename - --output-filename \$HOME/Pictures/Screenshots/screenshot-\$(date +'%Y-%m-%d_%H-%M-%S').png --early-exit --actions-on-enter save-to-clipboard --save-after-copy --copy-command wl-copy";
      "$wallpaper" = "/home/iperez/Wallpaper/1udeandomn1e1.jpeg";

      inherit (bind) bind;
      inherit (bind) bindel;
      inherit (bind) bindm;
      inherit (bind) bindl;
    };
  };
}
