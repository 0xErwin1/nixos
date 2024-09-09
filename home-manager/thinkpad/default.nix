{ pkgs, ... }:
{
  imports = [
    ../global/browser.nix
    ../global/rofi.nix
    ../global/kitty.nix
    ../global
    ../global/window-managers/leftwm
    ./xorg
  ];
  nixpkgs.config.allowUnfree = true;

  home = {
    enableNixpkgsReleaseCheck = false;
    username = "iperez";
    homeDirectory = "/home/iperez";
    stateVersion = "24.05";
    packages = with pkgs; [
      eza
      bat
      zsh
      curl
      wget
      btop
      delta
      discord
      slack
      dbeaver-bin
      arandr
      volumeicon
    ];
    sessionVariables = {
      EDITOR = "nvim";
    };
  };

  programs = {
    home-manager.enable = true;
  };
}
