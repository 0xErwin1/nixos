{ pkgs, ... }:
{
  imports = [
    ./pipewire-equalizers.nix
  ];

  home.packages = with pkgs; [
    vlc
    pavucontrol
  ];
}
