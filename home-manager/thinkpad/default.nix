{ pkgs, ... }:
{
  imports = [
    ../global
    ../global/kitty.nix
    ./leftwm
    ./browser.nix
  ];

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
  };
}
