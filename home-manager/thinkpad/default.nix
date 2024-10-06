{ pkgs, ... }:
{
  imports = [
    ../global/browser.nix
    ../global/rofi.nix
    ../global/kitty.nix
    ../global
    ../global/window-managers/leftwm
    ../global/window-managers/hyperland
    ../global/audio.nix
    ../global/themes.nix
    ../global/notify.nix
    ./xorg
    ./monitor.nix
  ];
  nixpkgs.config.allowUnfree = true;

  home = {
    enableNixpkgsReleaseCheck = false;
    username = "iperez";
    homeDirectory = "/home/iperez";
    stateVersion = "24.05";
    packages = with pkgs; [
      discord
      slack
      dbeaver-bin
      arandr
      volumeicon
      spotify
      lxappearance
      obsidian
      udevil
      simple-mtpfs
    ];
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

  services = {
    syncthing = {
      enable = true;
    };
    udiskie = {
      enable = true;
      tray = "always";
    };
  };
}
