{ ... }:
{
  imports = [
    ../global/browser.nix
    ../global/terminal.nix
    ../global
    ../global/xdg.nix
    ../global/zed
    ../global/font.nix
    #../global/window-managers/hyprland
    ../global/window-managers/leftwm
    ../global/audio.nix
    ../global/themes.nix
    ../global/communication.nix
    ../global/notify.nix
    ../global/database.nix
    ../global/neovim.nix
    ../global/zathura.nix
    ../global/music.nix
    ../global/x11
    ./x11.nix
    ./monitor.nix
    ./packages.nix
  ];

  home = {
    enableNixpkgsReleaseCheck = false;
    username = "iperez";
    homeDirectory = "/home/iperez";
    stateVersion = "25.11";
    sessionVariables = {
      EDITOR = "nvim";
    };
  };

  programs = {
    home-manager.enable = true;
  };
}
