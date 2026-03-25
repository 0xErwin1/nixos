{ pkgs, ... }:
{
  imports = [
    ./hardware-configuration.nix
    ../globals/wireguard/local.nix
    ../globals/wireguard
    ../globals
    ../globals/bluetooth.nix
    ../globals/pipewire.nix
    ./x11.nix
    ./cpu.nix
  ];

  systemd.services."NetworkManager-wait-online".enable = false;
  networking = {
    hostName = "zeta";
    networkmanager = {
      enable = true;
    };
  };

  services = {
    fprintd.enable = true;
    resolved.enable = true;
    fwupd.enable = true;
    openssh.enable = true;
    gnome.gnome-keyring.enable = true;

    syncthing = {
      enable = true;
      user = "iperez";
      dataDir = "/home/iperez";
      configDir = "/home/iperez/.config/syncthing";
      openDefaultPorts = true;
    };
  };

  location.provider = "geoclue2";

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

  environment.systemPackages = with pkgs; [
    cloudflared
  ];

  programs.hyprland = {
    enable = true;
    xwayland.enable = true;
  };

  system.stateVersion = "25.11";
}
