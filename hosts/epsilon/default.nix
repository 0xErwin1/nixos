{ pkgs, ... }:
{
  nixpkgs.config.allowUnfree = true;

  imports = [
    ./hardware-configuration.nix
    ../globals
    ../globals/gaming.nix
    ./packages.nix
    ./wireguard.nix
    ./wireguard-local.nix
    ./rdp.nix
  ];

  boot = {
    tmp.cleanOnBoot = true;
    loader = {
      systemd-boot.enable = true;
      efi.canTouchEfiVariables = true;
    };
  };

  networking = {
    hostName = "epsilon";
    networkmanager = {
      enable = true;
      dns = "systemd-resolved";
    };
    nameservers = [
      "1.1.1.1"
      "1.0.0.1"
    ];
  };

  services = {
    xserver = {
      enable = true;
      xkb = {
        layout = "us";
        variant = "";
      };
      autoRepeatDelay = 200;
      autoRepeatInterval = 40;

      displayManager.sessionCommands = ''
        set -g visual-bell off
        # xinput set-prop "TPPS/2 Elan TrackPoint" "libinput Accel Speed" -0.6
        export XCURSOR_SIZE=12
        xmodmap -e "remove Lock = Caps_Lock"
        xmodmap -e "keycode 66 = Control_L"
        xmodmap -e "add Control = Control_L"
      '';
      windowManager.leftwm.enable = true;
    };
    libinput.enable = true;
    pipewire = {
      enable = true;
      alsa = {
        enable = true;
        support32Bit = true;
      };
      pulse.enable = true;
      jack.enable = true;
      extraLv2Packages = with pkgs; [
        calf
        lsp-plugins
        mda_lv2
        rnnoise-plugin
        x42-plugins
        zam-plugins
      ];
      wireplumber.enable = true;
    };
    displayManager.ly.enable = true;
    geoclue2.enable = true;
    redshift = {
      enable = true;
      temperature = {
        day = 5000;
        night = 4000;
      };
    };
    gnome.gnome-keyring.enable = true;
    ratbagd.enable = true;
    blueman.enable = true;
    resolved = {
      enable = true;
    };

    syncthing = {
      enable = true;
      user = "iperez";
      dataDir = "/home/iperez";
      configDir = "/home/iperez/.config/syncthing";
      openDefaultPorts = true;
    };
  };
  systemd.services."NetworkManager-wait-online".enable = false;

  xdg = {
    portal = {
      enable = true;
      extraPortals = with pkgs; [
        xdg-desktop-portal-gtk
        xdg-desktop-portal-hyprland
      ];
      config.common.default = [
        "gtk"
        "hyprland"
      ];
    };
  };

  location.provider = "geoclue2";
  hardware.bluetooth.enable = true;

  security.rtkit.enable = true;

  programs = {
    hyprland = {
      enable = true;
      xwayland.enable = true;
    };
  };

  system.stateVersion = "25.11";
}
