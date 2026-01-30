{ pkgs, ... }:
{
  imports = [
    ../global/browser.nix
    ../global/terminal.nix
    ../global
    ../global/xdg.nix
    ../global/zed
    ../global/window-managers/hyprland
    ../global/audio.nix
    ../global/themes.nix
    ../global/notify.nix
    ../global/database.nix
    ../global/spotify.nix
    ./packages.nix
  ];

  home = {
    enableNixpkgsReleaseCheck = false;
    username = "iperez";
    homeDirectory = "/home/iperez";
    stateVersion = "25.05";
    sessionVariables = {
      EDITOR = "nvim";
      LAPTOP = "eDP";
      HDMI = "HDMI-A-0";
      DISPLAY_PORT = "DisplayPort-0";
      DISPLAY_PORT_1 = "DisplayPort-1";
    };
  };

  programs = {
    home-manager.enable = true;
  };
}
