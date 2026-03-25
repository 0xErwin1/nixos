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
    ../global/notify.nix
    ../global/neovim.nix
    ../global/zathura.nix
    ../global/music.nix
    ../global/communication.nix
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
      eww
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
}
