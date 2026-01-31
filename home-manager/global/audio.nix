{ pkgs, ... }:
{
  services.easyeffects.enable = true;
  services.wireplumber.enable = true;
  home.packages = with pkgs; [
    vlc
    pavucontrol
  ];
}
