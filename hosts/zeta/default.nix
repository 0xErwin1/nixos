{ ... }:
{
  imports = [
    ./hardware-configuration.nix
    ./wireguard.nix
    ./wireguard-local.nix
    ../globals
    ./x11.nix
    ./cpu.nix
  ];

  systemd.services."NetworkManager-wait-online".enable = false;
  networking = {
    hostName = "zeta";
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

  system.stateVersion = "25.11";
}
