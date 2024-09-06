{ pkgs, ... }:
{
  fonts.fontconfig.enable = true;

  home.packages = with pkgs; [
    nerdfonts
    powerline-symbols
    noto-fonts-emoji
  ];
}
