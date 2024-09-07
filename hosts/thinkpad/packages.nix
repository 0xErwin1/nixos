{ pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    wget
    mesa
    libglvnd
    libGL
    libGLX
    xorg.libX11
    leftwm
    eww
    qimgv
    nitrogen
    picom
    feh
  ];
}
