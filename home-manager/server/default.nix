{ config, pkgs, ... }:

{
  home = {
    enableNixpkgsReleaseCheck = false;
    username = "iperez";
    homeDirectory = "/home/iperez";
    stateVersion = "24.05";
    packages = [
      pkgs.eza
      pkgs.zsh
      pkgs.curl
      pkgs.wget
      pkgs.btop
      pkgs.firefox
      pkgs.delta
    ];
    sessionVariables = {
      EDITOR = "nvim";
    };
  };

  programs = {
    home-manager.enable = true;
    git = {
      enable = true;
      userName = "Ignacio Perez";
    };
    virt-manager.enable = true;
  };

  virtualisation = {
    docker.enable = true;
    libvirtd.enable = true;
  };

  users.users.iperez.extraGroups = [ "libvirtd" ];

  imports = [ ../global ];
}
