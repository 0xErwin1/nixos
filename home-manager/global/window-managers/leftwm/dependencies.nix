{ pkgs, ... }:
{
  home = {
    packages = with pkgs; [
      eww
      xclip
      brightnessctl
      pamixer
      playerctl
      scrot
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
