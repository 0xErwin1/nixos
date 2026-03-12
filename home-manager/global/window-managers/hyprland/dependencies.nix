{ pkgs, ... }:
{
  home = {
    packages = with pkgs; [
      eww
      brightnessctl
      jq
      socat
      pamixer
      playerctl
      wayland
      grim
      slurp
      swappy
      satty
      hyprpaper
      hyprlock
      hyprshot
    ];
  };
}
