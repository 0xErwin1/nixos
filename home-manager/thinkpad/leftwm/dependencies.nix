{ pkgs, ... }:
{
  home = {
    packages = with pkgs; [
      rofi
      eww
      xclip
    ];
  };

  programs = {
    rofi = {
      enable = true;
    };
  };
}
