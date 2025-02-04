{ pkgs, ... }:
{
  home.packages = with pkgs; [
    ncdu
    tokei
    fastfetch
    onefetch
    eza
    bat
    curl
    wget
    delta
    kalker
    fd
    pcmanfm
  ];
}
