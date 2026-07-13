{ pkgs, ... }:
{
  imports = [ ../headless ];

  home = {
    enableNixpkgsReleaseCheck = false;
    username = "iperez";
    homeDirectory = "/home/iperez";
    stateVersion = "26.05";
    sessionVariables.EDITOR = "nvim";
  };

  programs.home-manager.enable = true;
}
