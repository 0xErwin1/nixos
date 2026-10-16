{ pkgs, ... }:
{
  home.packages = with pkgs; [
    #code-cursor
    discord
    mono
    open-pencil
    open-pencil-mcp
    telegram-desktop
  ];
}
