{ pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    librewolf
    brave
    firefox
  ];
}
