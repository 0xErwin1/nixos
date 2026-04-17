{ pkgs, ... }:
{
  home.packages = with pkgs; [
    code-cursor
    slack
    teams-for-linux
    zoom
  ];
}
