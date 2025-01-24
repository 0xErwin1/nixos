{ pkgs, ... }:
{
  imports = [
    ../global/browser.nix
    ../global/rofi.nix
    ../global/terminal.nix
    ../global
    ../global/window-managers/leftwm
    ../global/audio.nix
    ../global/themes.nix
    ../global/notify.nix
    ../global/database.nix
    ../global/spotify.nix
    ./xorg
    ./monitor.nix
    ./picom.nix
  ];

  nixpkgs = {
    config.allowUnfree = true;
  };

  home = {
    enableNixpkgsReleaseCheck = false;
    username = "iperez";
    homeDirectory = "/home/iperez";
    stateVersion = "25.05";
    packages = with pkgs; [
      discord
      slack
      dbeaver-bin
      arandr
      volumeicon
      lxappearance
      obsidian
      udevil
      simple-mtpfs
    ];
    sessionVariables = {
      EDITOR = "nvim";
      LAPTOP = "eDP";
      HDMI = "HDMI-A-0";
      DISPLAY_PORT = "DisplayPort-0";
      DISPLAY_PORT_1 = "DisplayPort-1";
    };
  };

  programs = {
    home-manager.enable = true;
  };

  systemd.user.targets.tray = {
    Unit = {
      Description = "Tray Icon";
      After = [ "graphical-session-pre.target" ];
      PartOf = [ "graphical-session.target" ];
    };
  };

  services = {
    syncthing = {
      enable = true;
    };
    udiskie = {
      enable = true;
      notify = true;
      automount = true;
      tray = "always";
    };
    redshift = {
      enable = true;
      provider = "geoclue2";
      temperature = {
        day = 5000;
        night = 4000;
      };
    };
  };
}
