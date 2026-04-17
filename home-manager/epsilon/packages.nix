{ pkgs, ... }:
{
  home.packages = with pkgs; [
    code-cursor
    discord
    mono
    telegram-desktop
  ];
}
