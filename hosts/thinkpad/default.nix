{
  imports = [
    ./hardware-configuration.nix
    ../globals
    ./browser.nix
    ./packages.nix
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

  services = {
    xserver = {
      enable = true;
      xkb = {
        layout = "us";
        variant = "";
      };
      autoRepeatDelay = 200;
      autoRepeatInterval = 40;

      windowManager.leftwm = {
        enable = true;
      };
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

  security.rtkit.enable = true;
  nixpkgs.config.allowUnfree = true;

  system.stateVersion = "24.05";
}
