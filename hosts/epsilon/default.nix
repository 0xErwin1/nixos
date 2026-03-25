{ pkgs, lib, ... }:
{
  nixpkgs.config.allowUnfree = true;

  imports = [
    ./hardware-configuration.nix
    ./kernel.nix
    ../globals
    ../globals/gaming.nix
    ../globals/bluetooth.nix
    ../globals/pipewire.nix
    ./packages.nix
    ../globals/wireguard/local.nix
    ../globals/wireguard
    ./cloudflare-tunnel.nix
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
    };
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
      updateDbusEnvironment = true;
      dpi = 96;

      displayManager.sessionCommands = ''
        set -g visual-bell off
        # xinput set-prop "TPPS/2 Elan TrackPoint" "libinput Accel Speed" -0.6
        export XCURSOR_SIZE=12
        xmodmap -e "remove Lock = Caps_Lock"
        xmodmap -e "keycode 66 = Control_L"
        xmodmap -e "add Control = Control_L"
      '';
      windowManager.leftwm.enable = false;
    };
    openssh = {
      enable = true;
      ports = [ 22222 ];
      settings.X11Forwarding = true;
    };
    libinput.enable = true;
    displayManager.ly.enable = true;
    geoclue2.enable = true;
    redshift = {
      enable = true;
      temperature = {
        day = 4000;
        night = 4000;
      };
    };
    gnome.gnome-keyring.enable = true;
    ratbagd.enable = true;
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
      wlr.enable = true;
      extraPortals = with pkgs; [
        xdg-desktop-portal-hyprland
        xdg-desktop-portal-gtk
      ];
      config.common.default = "hyprland";
    };
  };

  location = {
    provider = "geoclue2";
    latitude = 0;
    longitude = 0;
  };

  security = {
    polkit.enable = true;
    rtkit.enable = true;
    pam = {
      services = {
        ly.fprintAuth = true;
        login = {
          fprintAuth = true;
          enableGnomeKeyring = true;
        };
        i3lock = {
          fprintAuth = true;
          enable = true;
        };
      };
    };
  };

  services.dbus.enable = true;

  programs = {
    hyprland = {
      enable = true;
      xwayland.enable = true;
    };
  };

  environment.sessionVariables = {
    WLR_NO_HARDWARE_CURSORS = "0";
    WLR_DRM_DEVICES = "/dev/dri/card0:/dev/dri/card1";
    __GLX_VENDOR_LIBRARY_NAME = "nvidia";
    GBM_BACKEND = "nvidia-drm";
    LIBVA_DRIVER_NAME = "nvidia";
  };

  system.stateVersion = "25.11";
}
