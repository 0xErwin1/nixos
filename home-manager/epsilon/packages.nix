{ pkgs, ... }:
{
  home.packages = with pkgs; [
    telegram-desktop
    cartero

    # Editors
    code-cursor

    # Communication
    slack
    teams-for-linux
    discord
  ];
}
