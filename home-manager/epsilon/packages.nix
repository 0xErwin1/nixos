{ pkgs, ... }:
{
  home.packages = with pkgs; [
    telegram-desktop
    cartero
    uv
    nodejs

    # Editors
    code-cursor

    # Communication
    slack
    teams-for-linux
    discord
  ];
}
