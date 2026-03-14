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
      nitrogen
    ];
  };

  programs = {
    rofi = {
      enable = true;
    };
  };
}
