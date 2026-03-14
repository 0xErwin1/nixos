{ pkgs, ... }:
{
  imports = [
    ./hardware-configuration.nix
    ./profiles/thin.nix
    ./wireguard.nix
    ./wireguard-local.nix
    ../globals
  ];

  boot = {
    tmp.cleanOnBoot = true;
    kernelPackages = pkgs.linuxPackages_latest;
    loader = {
      systemd-boot.enable = true;
      efi.canTouchEfiVariables = true;
    };
  };

  systemd.services."NetworkManager-wait-online".enable = false;
  networking = {
    hostName = "x13";
    networkmanager = {
      enable = true;
      dns = "systemd-resolved";
    };
    nameservers = [
      "10.0.0.1"
      "1.1.1.1"
      "1.0.0.1"
    ];
  };

  services = {
    fprintd.enable = true;
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
    displayManager.ly.enable = true;

    pipewire = {
      enable = true;
      alsa = {
        enable = true;
        support32Bit = true;
      };
      pulse.enable = true;
      jack.enable = true;
      wireplumber.enable = true;
    };

    blueman.enable = true;
    resolved.enable = true;
    thermald.enable = true;
    tlp.enable = true;
    fwupd.enable = true;
    openssh.enable = true;
    geoclue2.enable = true;
    redshift = {
      enable = true;
      temperature = {
        day = 5000;
        night = 4000;
      };
    };
    gnome.gnome-keyring.enable = true;
  };

  xdg.portal = {
    enable = true;
    extraPortals = with pkgs; [ xdg-desktop-portal-gtk ];
    config.common.default = [ "gtk" ];
  };

  security = {
    rtkit.enable = true;
    pam = {
      services = {
        ly.fprintAuth = true;
        login.fprintAuth = true;
        i3lock = {
          fprintAuth = true;
          enable = true;
        };
      };
    };
  };

  specialisation.full-lite.configuration = import ./profiles/full-lite.nix;

  system.stateVersion = "25.11";
}
