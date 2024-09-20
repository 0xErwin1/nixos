{ pkgs, ... }:
{
  home.packages = with pkgs; [ fastfetch ];
  programs.kitty = {
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
      term xterm-256color

      background_opacity 0.85

      [blur]
      background=true

      # Ayu Dark color scheme for Kitty

      background #0A0E14
      foreground #B3B1AD
      selection_background #073655
      selection_foreground #ffffff
      url_color #39bae6

      # Tabs
      active_tab_foreground #B3B1AD
      active_tab_background #0A0E14
      inactive_tab_foreground #6E7681
      inactive_tab_background #0A0E14

      # Normal colors
      color0  #0A0E14
      color1  #F07178
      color2  #C3E88D
      color3  #FFCB6B
      color4  #82AAFF
      color5  #C792EA
      color6  #89DDFF
      color7  #B3B1AD
      color8  #6E7681
      color9  #F07178
      color10 #C3E88D
      color11 #FFCB6B
      color12 #82AAFF
      color13 #C792EA
      color14 #89DDFF
      color15 #FFFFFF

      # Additional highlights
      cursor #FFCB6B
    '';
  };
}
