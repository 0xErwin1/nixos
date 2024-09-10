{ pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    wget
    mesa
    libglvnd
    libGL
    libGLX
    xorg.libX11
    xorg.xinput
    leftwm
    eww
    qimgv
    nitrogen
    picom
    feh
    xclip
  ];
}
