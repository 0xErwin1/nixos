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
      wayland
    ];
  };

  programs = {
    rofi = {
      enable = true;
    };
  };
}
