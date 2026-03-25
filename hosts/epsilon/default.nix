{ pkgs, ... }:
{
  nixpkgs.config.allowUnfree = true;

  imports = [
    ./hardware-configuration.nix
    ./kernel.nix
    ../globals
    ../globals/gaming.nix
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
      windowManager.leftwm.enable = true;
    };
    openssh = {
      enable = true;
      ports = [ 22222 ];
      settings.X11Forwarding = true;
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
      wireplumber = {
        enable = true;
        extraConfig."10-bluez-stability" = {
          "monitor.bluez.properties" = {
            "bluez5.enable-msbc" = true;
            "bluez5.enable-hw-volume" = true;
            "bluez5.roles" = [
              "a2dp_sink"
              "a2dp_source"
              "hsp_hs"
              "hsp_ag"
              "hfp_hf"
              "hfp_ag"
            ];
            "bluez5.hfphsp-backend" = "native";
            "bluez5.enable-sbc-xq" = true;
          };

          "wireplumber.settings" = {
            "bluetooth.autoswitch-to-headset-profile" = true;
            "bluetooth.use-persistent-storage" = true;
            "device.restore-profile" = true;
            "device.restore-routes" = true;
          };
        };
      };
    };
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
    blueman.enable = true;
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
  hardware.bluetooth.enable = true;

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

  system.stateVersion = "25.11";
}
