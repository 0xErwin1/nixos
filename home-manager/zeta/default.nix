{ pkgs, ... }:
{
  imports = [
    ../global
    ../global/browser.nix
    ../global/terminal.nix
    ../global/xdg.nix
    ../global/font.nix
    ../global/window-managers/hyprland
    ../global/audio.nix
    ../global/themes.nix
    ../global/neovim.nix
    ../global/zathura.nix
    ../global/music.nix
    ../global/voxtype.nix
    ../global/bar/default.nix
    ../global/calendar.nix
    ../global/communication.nix
    ../global/database.nix
    ../global/x11
    ./monitor.nix
    ./xorg.nix
  ];

  home = {
    enableNixpkgsReleaseCheck = false;
    username = "iperez";
    homeDirectory = "/home/iperez";
    stateVersion = "25.11";

    sessionVariables = {
      EDITOR = "nvim";
    };

    packages = with pkgs; [
      brightnessctl
      playerctl
      xclip
      arandr
      networkmanagerapplet
      firefox
    ];
  };

  programs = {
    home-manager.enable = true;
  };

  services = {
    syncthing = {
      enable = true;
      extraOptions = [
        "--config=/home/iperez/.config/syncthing"
        "--data=/home/iperez"
      ];
    };
  };
}
