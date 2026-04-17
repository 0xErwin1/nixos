{ pkgs, ... }:
{
  home.packages = with pkgs; [
    niri
    swaylock
    swaybg
    swayidle
    kanshi
    mako
    fuzzel
    wayland
    grim
    slurp
    swappy
    satty
    brightnessctl
    jq
    socat
    pamixer
    playerctl
  ];
}
