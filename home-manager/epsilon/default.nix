{ ... }:
{
  imports = [
    ../global/browser.nix
    ../global/terminal.nix
    ../global
    ../global/git.nix
    ../global/xdg.nix
    ../global/zed
    ../global/font.nix
    ../global/window-managers/hyprland
    ../global/window-managers/niri
    #../global/window-managers/leftwm
    ../global/audio.nix
    ../global/themes.nix
    ../global/communication.nix
    ../global/notify.nix
    ../global/database.nix
    ../global/neovim.nix
    ../global/zathura.nix
    ../global/music.nix
    #../global/x11
    #./x11.nix
    #./monitor.nix
    ./kanshi.nix
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
