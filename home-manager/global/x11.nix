{ pkgs, ... }:
{
  home = {
    packages = with pkgs; [
      eww
      xclip
      xrandr
      arandr
      brightnessctl
      pamixer
      playerctl
      betterlockscreen
      flameshot
      networkmanagerapplet
      blueman
      udiskie
      solaar
      feh
    ];
  };

  programs = {
    rofi = {
      enable = true;
    };
  };
}
