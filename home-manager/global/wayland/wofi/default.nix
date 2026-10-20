# Wofi styled as one more card of the Astal bar (home-manager/global/bar): same
# Ayu Dark palette, font, radius and border as `.dashboard-card`.
#
# The shared settings stay neutral (centered, one column) because `bt-menu`
# also drives wofi in dmenu mode. The application launcher size lives in the
# `app-launcher` wrapper instead, which also closes it on a second press.
{ pkgs, ... }:
let
  launcherFlags = [
    "--width 560"
    "--height 520"
  ];

  mkToggle =
    name: mode: prompt:
    pkgs.writeShellScriptBin name ''
      # A second press closes the open launcher instead of stacking another.
      if ${pkgs.procps}/bin/pkill -x wofi; then
        exit 0
      fi
      exec wofi --show ${mode} --prompt "${prompt}" ${builtins.concatStringsSep " " launcherFlags}
    '';
in
{
  home.packages = [
    (mkToggle "app-launcher" "drun" "Search applications")
    (mkToggle "window-switcher" "window" "Switch window")
  ];

  programs.wofi = {
    enable = true;
    settings = {
      show = "drun";
      prompt = "Search";
      width = 560;
      height = 420;
      location = "center";
      allow_markup = true;
      insensitive = true;
      matching = "multi-contains";
      term = "ghostty";
      columns = 1;
      hide_scroll = true;
      allow_images = true;
      image_size = 28;
      no_actions = true;
      gtk_dark = true;
      key_expand = "Tab";
    };
    # GTK3 CSS. The window itself stays transparent so the rounded corners of
    # #outer-box are not painted over by a square window background.
    style = ''
      @define-color background #0a0e14;
      @define-color foreground #bfbab0;
      @define-color grey #151720;
      @define-color yellow #ffb454;
      @define-color nix #5277c3;

      * {
        font-family: "JetBrainsMono Nerd Font";
        font-size: 14px;
        outline: none;
      }

      window {
        background-color: transparent;
      }

      #outer-box {
        background-color: @background;
        color: @foreground;
        border: 1px solid @grey;
        border-radius: 18px;
        padding: 14px;
      }

      #input {
        margin-bottom: 10px;
        padding: 8px 14px;
        border: none;
        border-radius: 999px;
        background-color: @grey;
        color: @foreground;
        box-shadow: none;
        caret-color: @yellow;
      }

      #input:focus {
        border: 1px solid alpha(@yellow, 0.35);
      }

      #input image {
        color: @nix;
      }

      #scroll,
      #inner-box {
        background-color: transparent;
      }

      /* GTK draws a dashed undershoot line at the scroll edge otherwise. */
      #scroll undershoot,
      #scroll overshoot {
        background: none;
      }

      #entry {
        padding: 6px 10px;
        margin: 1px 0;
        border-radius: 12px;
        background-color: transparent;
        transition: background-color 120ms ease;
      }

      #entry:hover {
        background-color: alpha(white, 0.06);
      }

      #entry:selected {
        background-color: @grey;
      }

      #entry:selected #text {
        color: @yellow;
        font-weight: bold;
      }

      #img {
        margin-right: 10px;
      }

      #text {
        color: @foreground;
      }
    '';
  };
}
