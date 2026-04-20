{ inputs, pkgs, ... }:
{
  imports = [
    inputs.niri-flake.homeModules.config
    ./dependencies.nix
    ./swaylock.nix
    ./swaybg.nix
    ./eww
  ];

  programs.niri = {
    package = pkgs.niri;

    settings = {
      input = {
        "mod-key" = "Super";
        "mod-key-nested" = "Alt";

        keyboard.xkb = {
          layout = "us";
          options = "ctrl:nocaps";
        };

        touchpad = {
          tap = true;
          "natural-scroll" = false;
        };
      };

      gestures."hot-corners".enable = false;

      "hotkey-overlay"."skip-at-startup" = true;

      workspaces = {
        "01-coding".name = "coding";
        "02-browser".name = "browser";
        "03-music".name = "music";
        "04-socials".name = "socials";
        "10-magic".name = "magic";
      };

      layout = {
        gaps = 5;
        "center-focused-column" = "never";

        "focus-ring" = {
          enable = true;
          width = 2;
          active.color = "#39bae6";
          inactive.color = "#c2d94c";
        };

        border = {
          enable = false;
          width = 1;
        };
      };

      "prefer-no-csd" = true;

      "screenshot-path" = "~/Pictures/Screenshots/Screenshot from %Y-%m-%d %H-%M-%S.png";

      environment = {
        NIXOS_OZONE_WL = "1";
        XCURSOR_THEME = "Bibata-Modern-Classic";
        XCURSOR_SIZE = "16";
        GDK_SCALE = "1";
        GDK_DPI_SCALE = "0.8";
        QT_AUTO_SCREEN_SCALE_FACTOR = "1";
      };

      "spawn-at-startup" = [
        {
          sh = ''
            eww -c "$HOME/.config/niri/eww" daemon
            eww -c "$HOME/.config/niri/eww" close-all >/dev/null 2>&1 || true
            eww -c "$HOME/.config/niri/eww" --force-wayland open-many laptop monitor-DP-0
          '';
        }
        {
          sh = ''
            pkill -x swaybg >/dev/null 2>&1 || true
            swaybg -m fill -i /home/iperez/Wallpaper/man-near-Torii-gate-wallpaper-gray-temple-wallpaper-landscape.jpg >/dev/null 2>&1 &
          '';
        }
        { argv = [ "nm-applet" ]; }
        { argv = [ "blueman-adapters" ]; }
        {
          argv = [
            "udiskie"
            "-t"
          ];
        }
        {
          argv = [
            "solaar"
            "-b"
            "regular"
            "-w"
            "hide"
          ];
        }
      ];

      binds = {
        "Mod+Return".action.spawn = "alacritty";
        "Mod+E".action.spawn = "pcmanfm";
        "Mod+B".action.spawn = "brave-origin-nightly";
        "Mod+Shift+B".action.spawn = "firefox";

        "Mod+M".action.spawn = "fuzzel";
        "Mod+Shift+M".action.spawn = [
          "fuzzel"
          "--show-actions"
        ];

        "Mod+P".action.spawn = [
          "sh"
          "-c"
          ''grim -g "$(slurp)" - | satty --filename - --output-filename "$HOME/Pictures/Screenshots/screenshot-$(date +'%Y-%m-%d_%H-%M-%S').png" --early-exit --actions-on-enter save-to-clipboard --save-after-copy --copy-command wl-copy''
        ];

        "Mod+Ctrl+L".action.spawn = "swaylock";

        "Mod+W".action."close-window" = [ ];
        "Mod+V".action."toggle-window-floating" = [ ];
        "Mod+F".action."toggle-window-floating" = [ ];
        "Mod+Space".action."fullscreen-window" = [ ];
        "Mod+Tab".action."toggle-column-tabbed-display" = [ ];
        "Mod+Z".action."center-column" = [ ];
        "Mod+Shift+Q".action.quit."skip-confirmation" = true;

        "Mod+H".action."focus-column-left" = [ ];
        "Mod+L".action."focus-column-right" = [ ];
        "Mod+K".action."focus-window-up" = [ ];
        "Mod+J".action."focus-window-down" = [ ];

        "Mod+Shift+H".action."move-column-left" = [ ];
        "Mod+Shift+L".action."move-column-right" = [ ];
        "Mod+Shift+K".action."move-window-up" = [ ];
        "Mod+Shift+J".action."move-window-down" = [ ];

        "Alt+Shift+H".action."set-column-width" = "-10%";
        "Alt+Shift+L".action."set-column-width" = "+10%";
        "Alt+Shift+J".action."set-window-height" = "+10%";
        "Alt+Shift+K".action."set-window-height" = "-10%";

        "Mod+X".action."focus-monitor-next" = [ ];
        "Mod+Shift+X".action."focus-monitor-previous" = [ ];

        "Mod+S".action."focus-workspace" = "magic";
        "Mod+Shift+S".action."move-window-to-workspace" = "magic";

        "Mod+1".action."focus-workspace" = 1;
        "Mod+2".action."focus-workspace" = 2;
        "Mod+3".action."focus-workspace" = 3;
        "Mod+4".action."focus-workspace" = 4;
        "Mod+5".action."focus-workspace" = 5;
        "Mod+6".action."focus-workspace" = 6;
        "Mod+7".action."focus-workspace" = 7;
        "Mod+8".action."focus-workspace" = 8;
        "Mod+9".action."focus-workspace" = 9;
        "Mod+0".action."focus-workspace" = 10;

        "Mod+Shift+1".action."move-window-to-workspace" = 1;
        "Mod+Shift+2".action."move-window-to-workspace" = 2;
        "Mod+Shift+3".action."move-window-to-workspace" = 3;
        "Mod+Shift+4".action."move-window-to-workspace" = 4;
        "Mod+Shift+5".action."move-window-to-workspace" = 5;
        "Mod+Shift+6".action."move-window-to-workspace" = 6;
        "Mod+Shift+7".action."move-window-to-workspace" = 7;
        "Mod+Shift+8".action."move-window-to-workspace" = 8;
        "Mod+Shift+9".action."move-window-to-workspace" = 9;
        "Mod+Shift+0".action."move-window-to-workspace" = 10;

        "Mod+WheelScrollDown" = {
          "cooldown-ms" = 150;
          action."focus-workspace-down" = [ ];
        };

        "Mod+WheelScrollUp" = {
          "cooldown-ms" = 150;
          action."focus-workspace-up" = [ ];
        };

        "XF86AudioRaiseVolume" = {
          "allow-when-locked" = true;
          action.spawn = [
            "wpctl"
            "set-volume"
            "-l"
            "1"
            "@DEFAULT_AUDIO_SINK@"
            "5%+"
          ];
        };

        "XF86AudioLowerVolume" = {
          "allow-when-locked" = true;
          action.spawn = [
            "wpctl"
            "set-volume"
            "@DEFAULT_AUDIO_SINK@"
            "5%-"
          ];
        };

        "XF86AudioMute" = {
          "allow-when-locked" = true;
          action.spawn = [
            "wpctl"
            "set-mute"
            "@DEFAULT_AUDIO_SINK@"
            "toggle"
          ];
        };

        "XF86AudioMicMute" = {
          "allow-when-locked" = true;
          action.spawn = [
            "wpctl"
            "set-mute"
            "@DEFAULT_AUDIO_SOURCE@"
            "toggle"
          ];
        };

        "XF86MonBrightnessUp" = {
          "allow-when-locked" = true;
          action.spawn = [
            "brightnessctl"
            "-e4"
            "-n2"
            "set"
            "5%+"
          ];
        };

        "XF86MonBrightnessDown" = {
          "allow-when-locked" = true;
          action.spawn = [
            "brightnessctl"
            "-e4"
            "-n2"
            "set"
            "5%-"
          ];
        };

        "XF86NotificationCenter".action.spawn = [
          "dunstctl"
          "set-paused"
          "toggle"
        ];

        "XF86AudioNext" = {
          "allow-when-locked" = true;
          action.spawn = [
            "playerctl"
            "next"
          ];
        };

        "XF86AudioPause" = {
          "allow-when-locked" = true;
          action.spawn = [
            "playerctl"
            "play-pause"
          ];
        };

        "XF86AudioPlay" = {
          "allow-when-locked" = true;
          action.spawn = [
            "playerctl"
            "play-pause"
          ];
        };

        "XF86AudioPrev" = {
          "allow-when-locked" = true;
          action.spawn = [
            "playerctl"
            "previous"
          ];
        };
      };
    };
  };

  programs.fuzzel.enable = true;
}
