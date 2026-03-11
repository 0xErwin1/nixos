{ pkgs, ... }:
{
  imports = [
    # Shell, git, tmux, direnv, utilities
    ../global

    # Font packages
    ../global/font.nix

    # Terminal (alacritty with colors + fonts)
    ../global/terminal.nix

    # Rofi launcher
    ../global/rofi.nix

    # XDG dirs
    ../global/xdg.nix

    # RDP scripts
    ./rdp-launchers.nix
  ];

  home = {
    enableNixpkgsReleaseCheck = false;
    username = "iperez";
    homeDirectory = "/home/iperez";
    stateVersion = "25.05";

    sessionVariables = {
      EDITOR = "nvim";
    };

    packages = with pkgs; [
      xclip
      arandr
      networkmanagerapplet
    ];

    file = {
      ".config/leftwm/config.ron".source = ./leftwm/thin/config.ron;
      ".config/leftwm/themes/current/up" = {
        source = ./leftwm/thin/up;
        executable = true;
      };
    };
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
    neovim.enable = true;
  };
}
