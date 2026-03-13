{ pkgs, ... }:
{
  home.packages = with pkgs; [
    gnupg
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

    opencode
    codex
    claude-code
  ];
}
