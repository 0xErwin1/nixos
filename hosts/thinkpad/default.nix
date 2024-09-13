{
  imports = [
    ./hardware-configuration.nix
    ../globals
    ../globals/gaming.nix
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

      displayManager.sessionCommands = ''
        xinput set-prop "TPPS/2 Elan TrackPoint" "libinput Accel Speed" -0.6
        export XCURSOR_SIZE=12
        xmodmap -e "remove Lock = Caps_Lock"
        xmodmap -e "keycode 66 = Control_L"
        xmodmap -e "add Control = Control_L"
      '';
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
    geoclue2.enable = true;
    redshift = {
      enable = true;
      temperature = {
        day = 5000;
        night = 5000;
      };
    };
    gnome.gnome-keyring.enable = true;
    ratbagd.enable = true;
    blueman.enable = true;
  };
  systemd.services."NetworkManager-wait-online".enable = false;

  location.provider = "geoclue2";

  virtualisation = {
    docker.enable = true;
    libvirtd.enable = true;
  };
  users.users.iperez.extraGroups = [ "libvirtd" ];

  security.rtkit.enable = true;
  nixpkgs.config.allowUnfree = true;

  system.stateVersion = "24.05";
}
