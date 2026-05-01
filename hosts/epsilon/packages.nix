{ pkgs, ... }:
{
  imports = [ ./virtualisation.nix ];

  environment.systemPackages = with pkgs; [
    wget
    mesa
    mesa-demos
    libglvnd
    libGL
    libGLX
    libX11
    xclip
    xinput
    xmodmap
    thinkfan
    ripgrep
    piper
    pwvucontrol
    unzip
    gzip
    zip
    cloudflared
    seahorse
    gnome-keyring
    gcr
  ];
}
