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
    btop
    delta
    kalker
    fd
    pcmanfm
  ];
}
