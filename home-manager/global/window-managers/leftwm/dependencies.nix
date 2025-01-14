{ pkgs, ... }:
{
  home = {
    packages = with pkgs; [
      eww
      xclip
      brightnessctl
      pamixer
      playerctl
      betterlockscreen
      flameshot
    ];
  };

  programs = {
    rofi = {
      enable = true;
    };
  };
}
