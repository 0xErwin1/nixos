{ config, pkgs, ... }:
{
  imports = [
    ./android.nix
    ./hardware-configuration.nix
    ./secrets.nix
    ./virtualisation.nix
    ./wireguard.nix
  ];

  nixpkgs.config.allowUnfree = true;

  boot = {
    kernelPackages = pkgs.linuxPackages_latest;
    loader = {
      systemd-boot = {
        enable = true;
        # Boot with the kernel DTB instead of the firmware-provided one so the
        # usb3-host-power overlay takes effect.
        installDeviceTree = true;
      };
      efi.canTouchEfiVariables = true;
    };
  };

  hardware.deviceTree = {
    name = "rockchip/rk3588-orangepi-5-plus.dtb";
    overlays = [
      {
        name = "usb3-host-power";
        dtsFile = ./usb3-host-power.dtso;
      }
    ];
  };

  networking = {
    hostName = "pi";
    useDHCP = false;
    networkmanager = {
      enable = true;
      wifi.powersave = false;
      ensureProfiles = {
        environmentFiles = [ config.sops.templates."networkmanager.env".path ];
        profiles = {
          pi-wifi = {
            connection = {
              id = "pi-wifi";
              type = "wifi";
              interface-name = "wlu1";
              uuid = "4695ce6d-f84f-4354-bd4f-75c7dc65adae";
            };
            wifi = {
              mode = "infrastructure";
              ssid = "$PI_WIFI_SSID";
            };
            wifi-security = {
              key-mgmt = "wpa-psk";
              psk = "$PI_WIFI_PSK";
            };
            ipv4 = {
              address1 = "192.168.1.100/24,192.168.1.1";
              dns = "192.168.1.1;";
              method = "manual";
            };
            ipv6.method = "auto";
          };
          pi-ethernet = {
            connection = {
              id = "pi-ethernet";
              type = "ethernet";
              interface-name = "enP4p65s0";
            };
            ipv4.method = "auto";
            ipv6.method = "auto";
          };
        };
      };
    };
  };

  services = {
    openssh = {
      enable = true;
      settings = {
        PasswordAuthentication = false;
        KbdInteractiveAuthentication = false;
        PermitRootLogin = "no";
        X11Forwarding = true;
      };
    };
    postgresql.enable = false;
    mysql.enable = false;
    xserver.enable = false;
  };

  users = {
    mutableUsers = true;
    users.iperez = {
      isNormalUser = true;
      extraGroups = [
        "networkmanager"
        "wheel"
      ];
      shell = pkgs.zsh;

      # Home Manager user services (herdr-server, chromium-cdp) must survive
      # reboots and closed SSH sessions, which only happens with lingering.
      linger = true;
      openssh.authorizedKeys.keys = [
        "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCWZRjt2GVSLcoBvSOS9AlxAxdQ/vvvFHLeT8m9KN3LEIEDB3ZiioX3sHt2xuIq5iKSZw+Co2iv3N0XYDmJ5ktElp2allK78xeQJ35BQmpNwPZCbiBHVDmJxeLLmRNilLz6NHWkjO+4qgyJGEgRJaUYDz8wg3RSPocDsVNIJhQ8TjmcPzAXTeb0v+tNR6CrvgQ0rux8XK6XQbpdJgv5Xi5Qi3ULTwRPR0v3fvYNJMKl6O9R7BsWUNGkN3/wlkeUfFPCMGU2+XCna6RQtLTGqyJ9o++yIxEcHVuWKNj8/32SnAuu1M0ZiJIo9TN48bN59MZ5msCFW0TmJoaNsIasZYvh"
      ];
    };
  };

  nix.settings.trusted-users = [ "iperez" ];
  # hosts/pi does not import hosts/globals, so the flake experimental features
  # that the graphical hosts get there have to be enabled explicitly here.
  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];

  programs.zsh.enable = true;

  time.timeZone = "America/Montevideo";

  system.stateVersion = "26.05";
}
