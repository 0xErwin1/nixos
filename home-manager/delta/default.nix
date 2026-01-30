{ pkgs, ... }:
{
  imports = [
    ../global
    ../global/rofi.nix
    ../global/xdg.nix
    ../global/notify.nix
    ../global/database.nix
    ../global/neovim.nix
    ../global/music.nix
    ./monitor.nix
    ./packages.nix
  ];

  nixpkgs.config.allowUnfree = true;
  targets.genericLinux.enable = true;

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
