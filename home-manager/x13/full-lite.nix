{ pkgs, ... }:
{
  imports = [
    ../global
    ../global/rofi.nix
    ../global/xdg.nix
    ../global/notify.nix
    ../global/neovim.nix
    ../global/font.nix
    ../global/themes.nix
    ../global/audio.nix
    ../global/window-managers/hyprland
    ../global/window-managers/leftwm
    ./rdp-launchers.nix
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

    packages = with pkgs; [
      telegram-desktop
      firefox
    ];
  };

  programs.home-manager.enable = true;
}
