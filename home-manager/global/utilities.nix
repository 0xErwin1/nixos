{ pkgs, ... }:
{
  programs = {
    codex.enable = true;
    claude-code.enable = true;
    opencode = {
      enable = true;
      package = pkgs.opencode;
    };
    uv.enable = true;
    go.enable = true;
    awscli = {
      enable = true;
      package = pkgs.awscli2;
    };
    delta.enable = true;
    fd.enable = true;
    fastfetch.enable = true;
  };

  services.udiskie = {
    enable = true;
  };

  home.packages = with pkgs; [
    gnupg
    ncdu
    tokei
    onefetch
    curl
    wget
    kalker
    pcmanfm
    btop
    postman
    cartero

    obsidian

    glab

    engram

    pnpm
    nodejs

    openvpn
    openfortivpn
    openssl
    claude-desktop

    pi-coding-agent

    tuicr
  ];
}
