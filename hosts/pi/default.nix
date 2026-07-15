{ pkgs, ... }:
{
  imports = [
    ./hardware-configuration.nix
    ./virtualisation.nix
    ./wireguard.nix
  ];

  nixpkgs.config.allowUnfree = true;

  boot = {
    kernelPackages = pkgs.linuxPackages_latest;
    loader = {
      systemd-boot.enable = true;
      efi.canTouchEfiVariables = true;
    };
  };

  networking = {
    hostName = "pi";
    useDHCP = false;
    interfaces.enP4p65s0.ipv4.addresses = [
      {
        address = "10.42.0.2";
        prefixLength = 24;
      }
    ];
    defaultGateway = "10.42.0.1";
    nameservers = [
      "1.1.1.1"
      "8.8.8.8"
    ];
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
      extraGroups = [ "wheel" ];
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
