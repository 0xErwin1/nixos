{ pkgs, ... }:
{
  programs.hyprland = {
    enable = true;
    xwayland.enable = true;
  };

  environment.systemPackages = with pkgs; [
    wget
    qimgv
    ripgrep
    piper
    pwvucontrol
    unzip
    gzip
    zip
    wl-clipboard
    xinput
    xmodmap
  ];
}
