{ pkgs, ... }:
{
  imports = [ ./virtualisation.nix ];

  environment.systemPackages = with pkgs; [
    wget
    mesa
    libglvnd
    libGL
    libGLX
    xorg.libX11
    xorg.xinput
    xorg.xmodmap
    xclip
    leftwm
    eww
    qimgv
    nitrogen
    picom
    feh
    thinkfan
    ripgrep
    piper
    pwvucontrol
    unzip
    gzip
    zip
  ];
}
