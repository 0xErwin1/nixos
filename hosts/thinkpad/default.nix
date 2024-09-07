{ pkgs, ... }:
{
  imports = [
    ../globals
    ./hardware-configuration.nix
    ./browser.nix
  ];

  boot = {
    loader = {
      systemd-boot.enable = true;
      efi.canTouchEfiVariables = true;
    };
  };

  networking = {
    hostName = "thinkpad";
    networkmanager.enable = true;
    nameservers = [
      "1.1.1.1"
      "1.0.0.1"
    ];
  };

  # Enable the X11 windowing system.
  services = {
    xserver = {
      enable = true;
      xkb = {
        layout = "us";
        variant = "";
      };
      autoRepeatDelay = 200;
      autoRepeatInterval = 40;
    };
    libinput.enable = true;
    pipewire = {
      enable = true;
      alsa = {
        enable = true;
        support32Bit = true;
      };
      pulse.enable = true;
    };
    displayManager = {
      ly.enable = true;
    };
  };

  hardware.pulseaudio.enable = false;
  security.rtkit.enable = true;
  nixpkgs.config.allowUnfree = true;

  environment.systemPackages = with pkgs; [
    wget
    mesa
    libglvnd
    libGL
    libGLX
    xorg.libX11
    leftwm
  ];

  system.stateVersion = "24.05";
}
