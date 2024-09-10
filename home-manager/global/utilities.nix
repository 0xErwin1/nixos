{ pkgs, ... }:
{
  home.packages = with pkgs; [
    nchat
    ncdu
  ];
}
