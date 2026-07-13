{ pkgs, ... }:
{
  imports = [ ./ai-headless.nix ];

  home.packages = with pkgs; [
    claude-desktop
  ];
}
