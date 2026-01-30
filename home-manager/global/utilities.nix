{ pkgs, ... }:
{
  home.packages = with pkgs; [
    ncdu
    tokei
    fastfetch
    onefetch
    curl
    wget
    delta
    kalker
    fd
    pcmanfm
    btop
  ];
}
