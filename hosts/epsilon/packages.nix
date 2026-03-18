{ pkgs, ... }:
{
  imports = [ ./virtualisation.nix ];

  environment.systemPackages = with pkgs; [
    wget
    mesa
    libglvnd
    libGL
    libGLX
    libX11
    xclip
    xinput
    xmodmap
    qimgv
    thinkfan
    ripgrep
    piper
    pwvucontrol
    unzip
    gzip
    zip
    cloudflared
  ];
}
