# Colors come from the active wl-theme (home-manager/global/theme): the sourced
# file defines the $wl_* variables used below, and `source` renders first. The
# wallpaper is the same in every theme, so text and field draw a $wl_shadow
# halo to stay legible when a light theme puts dark text on it.
{ config, ... }:
let
  shadow = {
    shadow_passes = 3;
    shadow_size = 6;
    shadow_boost = 1.4;
    shadow_color = "$wl_shadow";
  };
in
{
  imports = [ ../../theme ];

  programs.hyprlock = {
    enable = true;
    settings = {
      source = [ "${config.xdg.stateHome}/wl-theme/current/hyprlock.conf" ];

      general = {
        no_fade_in = true;
        no_fade_out = true;
        hide_cursor = false;
        grace = 0;
        disable_loading_bar = true;
      };

      background = [
        {
          monitor = "";
          path = "$wallpaper";
          blur_passes = 2;
          contrast = 1;
          brightness = 0.9;
          vibrancy = 0.0;
          vibrancy_darkness = 0.0;
        }
      ];

      input-field = map (widget: widget // shadow) [
        {
          monitor = "";
          size = "250, 60";
          outline_thickness = 2;
          dots_size = 0.3;
          dots_spacing = 0.35;
          dots_center = true;
          outer_color = "rgba(0, 0, 0, 0)";
          inner_color = "$wl_field";
          font_color = "$wl_text";
          fade_on_empty = false;
          rounding = -1;
          check_color = "$wl_accent";
          placeholder_text = "Input Password...";
          hide_input = false;
          position = "0, -200";
          halign = "center";
          valign = "center";
        }
      ];

      label = map (widget: widget // shadow) [
        # Time
        {
          monitor = "";
          text = "cmd[update:60] echo \"$(date +\"%-H:%M\")\"";
          color = "$wl_text_soft";
          font_size = 95;
          font_family = "LiterationMono Nerd Font";
          position = "0, 200";
          halign = "center";
          valign = "center";
        }

        # Date
        {
          monitor = "";
          text = "cmd[update:60] echo \"$(date +\"%A, %d %B %Y\")\"";
          color = "$wl_text_dim";
          font_size = 22;
          font_family = "LiterationMono Nerd Font";
          position = "0, 300";
          halign = "center";
          valign = "center";
        }
      ];
    };
  };
}
