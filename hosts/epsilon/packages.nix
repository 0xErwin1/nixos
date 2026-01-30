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
    wl-clipboard
    qimgv
    thinkfan
    ripgrep
    piper
    pwvucontrol
    unzip
    gzip
    zip
  ];
}
