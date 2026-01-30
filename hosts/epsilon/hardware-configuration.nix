{
  pkgs,
  config,
  lib,
  modulesPath,
  ...
}:
{
  imports = [
    ./kernel.nix
    (modulesPath + "/installer/scan/not-detected.nix")
  ];

  environment.etc."throttled.conf".source = ./throttled.conf;

  boot = {
    initrd = {
      availableKernelModules = [
        "xhci_pci"
        "nvme"
        "usbhid"
        "usb_storage"
        "sdhci_pci"
        "thunderbolt"
      ];
      kernelModules = [ ];
      luks.devices."root".device = "/dev/disk/by-uuid/a960b1d8-aa18-4925-b4dc-76eed2c5ed4d";
    };

    kernelModules = [
      "kvm-intel"
      "thinkpad_acpi"
      "fuse"
      "acpi_call"
    ];
    extraModulePackages = with config.boot.kernelPackages; [ acpi_call ];

    blacklistedKernelModules = [ "pcspkr" ];

    extraModprobeConfig = ''
      options thinkpad_acpi fan_control=1
    '';

    kernel.sysctl = {
      "vm.swappiness" = 180;
      "vm.watermark_boost_factor" = 0;
      "vm.watermark_scale_factor" = 125;
      "vm.page-cluster" = 0;
    };

    supportedFilesystems = [
      "btrfs"
      "vfat"
      "fuse"
      "ntfs"
      "exfat"
    ];
  };

  fileSystems."/" = {
    device = "/dev/mapper/root";
    fsType = "btrfs";
    options = [
      "subvol=@nixos"
      "compress=zstd"
      "noatime"
      "ssd"
      "space_cache=v2"
    ];
  };

  fileSystems."/home" = {
    device = "/dev/mapper/root";
    fsType = "btrfs";
    options = [
      "subvol=@nixos-home"
      "compress=zstd"
      "noatime"
      "ssd"
      "space_cache=v2"
    ];
  };

  fileSystems."/boot" = {
    device = "/dev/disk/by-uuid/5990-8457";
    fsType = "vfat";
    options = [ "fmask=0022" "dmask=0022" ];
  };

  fileSystems."/swap" = {
    device = "/dev/mapper/root";
    fsType = "btrfs";
    options = [ "subvol=swap" "noatime" ];
  };

  # zram swap for daily use
  zramSwap = {
    enable = true;
    algorithm = "zstd";
    memoryPercent = 10;
  };

  # BTRFS swapfile for hibernation
  swapDevices = [{
    device = "/swap/swapfile";
    priority = 100;
  }];

  hardware = {
    enableRedistributableFirmware = true;
    cpu.intel.updateMicrocode = true;

    bluetooth = {
      enable = true;
      powerOnBoot = true;
    };

    graphics = {
      enable = true;
      enable32Bit = true;
      extraPackages = with pkgs; [
        intel-media-driver
        intel-vaapi-driver
        libvdpau-va-gl
        libva-vdpau-driver
      ];
    };

    nvidia = {
      modesetting.enable = true;
      powerManagement.enable = true;
      powerManagement.finegrained = true;
      open = false;
      nvidiaSettings = true;
      package = config.boot.kernelPackages.nvidiaPackages.stable;

      prime = {
        offload = {
          enable = true;
          enableOffloadCmd = true;
        };
        intelBusId = "PCI:0:2:0";
        nvidiaBusId = "PCI:1:0:0";
      };
    };
  };

  networking.useDHCP = lib.mkDefault true;

  services = {
    fwupd.enable = true;
    thermald.enable = true;

    # Throttled for Intel CPU power limits (PL1/PL2)
    throttled.enable = true;

    tlp = {
      enable = true;
      settings = {
        CPU_SCALING_GOVERNOR_ON_AC = "performance";
        CPU_SCALING_GOVERNOR_ON_BAT = "powersave";

        CPU_ENERGY_PERF_POLICY_ON_AC = "performance";
        CPU_ENERGY_PERF_POLICY_ON_BAT = "balance_power";

        CPU_MIN_PERF_ON_AC = 0;
        CPU_MAX_PERF_ON_AC = 100;
        CPU_MIN_PERF_ON_BAT = 25;
        CPU_MAX_PERF_ON_BAT = 60;

        CPU_BOOST_ON_AC = 1;
        CPU_BOOST_ON_BAT = 0;

        PLATFORM_PROFILE_ON_AC = "performance";
        PLATFORM_PROFILE_ON_BAT = "balanced";
      };
    };

    fprintd.enable = true;

    thinkfan = {
      enable = true;
      smartSupport = true;
      sensors = [
        {
          type = "hwmon";
          query = "/sys/devices/platform/thinkpad_hwmon/hwmon";
          indices = [ 0 ];
        }
      ];
      fans = [
        {
          type = "tpacpi";
          query = "/proc/acpi/ibm/fan";
        }
      ];
      levels = [
        [ 0 0 55 ]
        [ 1 53 60 ]
        [ 2 58 65 ]
        [ 3 63 70 ]
        [ 4 68 75 ]
        [ 5 73 80 ]
        [ 6 78 85 ]
        [ 7 83 90 ]
        [ "level auto" 88 32767 ]
      ];
    };

    xserver.videoDrivers = [ "nvidia" ];
  };

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
}
