{ pkgs, ... }:
{
  imports = [ ../global ];
  home = {
    enableNixpkgsReleaseCheck = false;
    username = "iperez";
    homeDirectory = "/home/iperez";
    stateVersion = "24.11";
    packages = with pkgs; [
      eza
      zsh
      curl
      wget
      btop
      firefox
      delta
      chromium
      mesa
      libglvnd
      mesa-demos
    ];
    sessionVariables = {
      EDITOR = "nvim";
    };
  };

  programs = {
    home-manager.enable = true;
  };

  services = {
    syncthing = {
      enable = true;
    };
  };
}
