{ pkgs, inputs, ... }:
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
    postman
    cartero

    opencode
    codex
    claude-code
    obsidian

    inputs.engramFlake.packages.${pkgs.system}.default

    pnpm
    nodejs
    uv
    go
    awscli2
  ];
}
