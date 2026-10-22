{ pkgs, config, ... }:
{
  # The colors come from the active wl-theme.
  imports = [ ./theme ];

  home.packages = with pkgs; [
    ghostty
  ];

  xdg.configFile."ghostty/config".text = ''
    # Fonts
    font-family = "JetBrainsMono NerdFont"
    font-size = 14
    font-style = Regular

    # Colors: the whole palette comes from the active theme (wl-theme).
    # `?` keeps a missing theme file from being an error; Ghostty applies a
    # palette change to windows opened after the switch.
    config-file = ?${config.xdg.stateHome}/wl-theme/current/ghostty.conf

    # Window
    window-padding-x = 0
    window-padding-y = 0
    background-opacity = 0.9

    # Clipboard
    copy-on-select = false

    # Shell
    shell-integration-features = cursor,no-sudo,title,ssh-env

    keybind = shift+enter=text:\x1b[13;2u
  '';

  programs = {
    alacritty = {
      enable = true;
      settings = {
        keyboard = {
          bindings = [
            {
              key = "Return";
              mods = "Shift";
              chars = builtins.fromJSON ''"\u001b[13;2u"'';
            }
          ];
        };
        env = {
          TERM = "xterm-256color";
          COLORTERM = "24bit";
          WINIT_X11_SCALE_FACTOR = "1.0";
        };
        font = {
          normal = {
            family = "JetBrains Mono Nerd Font";
            style = "Regular";
          };
          bold = {
            family = "JetBrains Mono Nerd Font";
            style = "Bold";
          };
          italic = {
            family = "JetBrains Mono Nerd Font";
            style = "Italic";
          };
          size = 13;
          offset = {
            x = 0;
            y = 0;
          };
        };
        window = {
          opacity = 0.9;
          decorations = "none";
          dynamic_padding = true;
          padding = {
            x = 0;
            y = 0;
          };
        };
        colors = {
          primary = {
            background = "#0A0E14";
            foreground = "#B3B1AD";
          };
          normal = {
            black = "#0A0E14";
            red = "#F07178";
            green = "#C3E88D";
            yellow = "#FFCB6B";
            blue = "#82AAFF";
            magenta = "#C792EA";
            cyan = "#89DDFF";
            white = "#B3B1AD";
          };
          bright = {
            black = "#6E7681";
            red = "#F07178";
            green = "#C3E88D";
            yellow = "#FFCB6B";
            blue = "#82AAFF";
            magenta = "#C792EA";
            cyan = "#89DDFF";
            white = "#FFFFFF";
          };
        };
      };
    };

    kitty = {
      enable = true;
      shellIntegration.enableZshIntegration = true;
      settings = {
        enable_audio_bell = false;
      };
      font = {
        name = "JetBrains Mono Nerd Font";
        size = 13;
      };
      extraConfig = ''
        map shift+enter send_text all \x1b[13;2u
        map ctrl+shift+h discard_event
        term xterm-256color

        background_opacity 0.85

        [blur]
        background=true

        # Colors follow the active desktop theme (wl-theme).
        include ${config.xdg.stateHome}/wl-theme/current/kitty.conf
      '';
    };
  };
}
