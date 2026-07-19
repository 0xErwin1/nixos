{ pkgs, lib, ... }:
{
  nixpkgs.config.allowUnfree = true;

  imports = [
    ./hardware-configuration.nix
    ./kernel.nix
    ../globals/android.nix
    ../globals
    ../globals/gaming.nix
    ../globals/bluetooth.nix
    ../globals/pipewire.nix
    ./packages.nix
    ../globals/wireguard/local.nix
    ../globals/wireguard
    ./flatpak.nix
    ./cloudflare-tunnel.nix
  ];

  boot = {
    tmp.cleanOnBoot = true;
    loader = {
      systemd-boot.enable = true;
      efi.canTouchEfiVariables = true;
    };
    binfmt.emulatedSystems = [ "aarch64-linux" ];
  };

  networking = {
    hostName = "epsilon";
    networkmanager = {
      enable = true;
    };
  };

  services = {
    seatd.enable = true;
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
    gnome.gnome-keyring.enable = true;
    ratbagd.enable = true;
  };
  systemd.services."NetworkManager-wait-online".enable = false;

  xdg = {
    portal = {
      enable = true;
      extraPortals = with pkgs; [
        xdg-desktop-portal-hyprland
        xdg-desktop-portal-gtk
      ];
      config.common = {
        default = [
          "hyprland"
          "gtk"
        ];
        "org.freedesktop.impl.portal.FileChooser" = [ "gtk" ];
        "org.freedesktop.impl.portal.OpenURI" = [ "gtk" ];
        "org.freedesktop.impl.portal.Settings" = [ "gtk" ];
      };
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

  # Stable colon-free DRM symlinks for AQ_DRM_DEVICES: cardN numbering shifts
  # across boots, and the by-path names cannot be used directly because
  # aquamarine splits the variable on every ':', including the ones inside
  # PCI addresses. ID_PATH is the same source udev uses to build by-path.
  services.udev.extraRules = ''
    ACTION=="add|change", SUBSYSTEM=="drm", KERNEL=="card*", ENV{ID_PATH}=="pci-0000:00:02.0", SYMLINK+="dri/igpu-card"
    ACTION=="add|change", SUBSYSTEM=="drm", KERNEL=="card*", ENV{ID_PATH}=="pci-0000:01:00.0", SYMLINK+="dri/dgpu-card"
  '';

  programs = {
    hyprland = {
      enable = true;
      xwayland.enable = true;
    };
  };

  environment.systemPackages = with pkgs; [
    xwayland-satellite
    swaylock
    swaybg
    swayidle
    kanshi
    mako
    fuzzel
  ];

  environment.sessionVariables = {
    WLR_NO_HARDWARE_CURSORS = "0";
    # Intel iGPU renders (primary); NVIDIA is included only to scan out DP-1,
    # which is wired to it. The symlinks come from the udev rules above.
    AQ_DRM_DEVICES = "/dev/dri/igpu-card:/dev/dri/dgpu-card";
    LIBVA_DRIVER_NAME = "iHD";
  };

  system.stateVersion = "25.11";
}
