{ pkgs, ... }:

{
  imports = [ ./virtualisation.nix ];
  programs.hyprland.enable = true;
  environment.systemPackages = with pkgs; [
    wget
    mesa
    libglvnd
    libGL
    libGLX
    xorg.libX11
    xorg.xinput
    xorg.xinput
    xorg.xmodmap
    leftwm
    eww
    qimgv
    nitrogen
    picom
    feh
    xclip
    thinkfan
    ripgrep
    piper
    pwvucontrol
    unzip
    gzip
    zip

  ];
}
