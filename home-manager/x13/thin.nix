{ pkgs, ... }:
{
  imports = [
    # Shell, git, tmux, direnv, utilities
    ../global
    ../global/neovim.nix

    # Font packages
    ../global/font.nix

    # Terminal (alacritty with colors + fonts)
    ../global/terminal.nix

    # Rofi launcher
    ../global/rofi.nix

    # XDG dirs
    ../global/xdg.nix

    # LeftWM — same config.ron as every host, x13-thin theme
    ../global/window-managers/leftwm

    # RDP scripts
    ./rdp-launchers.nix

    ../global/neovim.nix
  ];

  leftwm.theme = "x13-thin";

  home = {
    enableNixpkgsReleaseCheck = false;
    username = "iperez";
    homeDirectory = "/home/iperez";
    stateVersion = "25.05";

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

  services.picom = {
    enable = true;
    backend = "xrender";
    vSync = false;
    fade = false;
    shadow = false;
  };

  programs = {
    home-manager.enable = true;
  };
}
