{ pkgs, ... }:
{
  home = {
    packages = with pkgs; [
      eww
      xclip
      brightnessctl
      pamixer
    ];
  };

  programs = {
    rofi = {
      enable = true;
    };
  };
}
