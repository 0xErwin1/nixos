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
    fuse
    fuse3
    appimage-run
  ];

  programs = {
    nix-ld = {
      enable = true;
      libraries = with pkgs; [
        fuse
        libusb
        libva
      ];
    };
    virt-manager = {
      enable = true;
    };
  };
}
