{ pkgs, ... }:
{
  home.packages = with pkgs; [
    nchat
    ncdu
    tokei
    fastfetch
    onefetch
    eza
    bat
    zsh
    curl
    wget
    btop
    delta
    kalker
    udiskie
    fd
    ripgrep
  ];
}
