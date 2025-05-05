{ pkgs, ... }:
{
  imports = [
    #    ../global/browser.nix
    ../global/rofi.nix
    #    ../global/terminal.nix
    ../global
    ../global/xdg.nix
    #   ../global/window-managers/leftwm
    #   ../global/audio.nix
    #../global/themes.nix
    ../global/notify.nix
    ../global/database.nix
    ../global/spotify.nix
    #  ./xorg
    ./monitor.nix
    ./packages.nix
    #  ./picom.nix
  ];

  nixpkgs = {
    config.allowUnfree = true;
  };

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
