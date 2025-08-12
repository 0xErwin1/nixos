{ pkgs, ... }:
{
  home = {
    packages = with pkgs; [
      eww
      brightnessctl
      pamixer
      playerctl
      wayland
      grim
      slurp
      swappy
      hyprpaper
      hyprlock
    ];
  };
}
