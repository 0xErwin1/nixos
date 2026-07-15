{ pkgs, ... }:
{
  programs = {
    uv.enable = true;
    go.enable = true;
    awscli = {
      enable = true;
      package = pkgs.awscli2;
    };
    delta.enable = true;
    fd.enable = true;
    fastfetch.enable = true;
    nh = {
      enable = true;
      flake = "/home/iperez/.config/home-manager";
      clean = {
        enable = true;
        extraArgs = "--keep-since 7d --keep 5";
      };
    };
  };

  home.packages = with pkgs; [
    btop
    curl
    glab
    gnupg
    kalker
    ncdu
    nodejs
    onefetch
    openssl
    pnpm
    python3
    tokei
    wget
  ];
}
