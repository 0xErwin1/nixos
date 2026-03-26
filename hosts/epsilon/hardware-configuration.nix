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
      luks.devices."data".device = "/dev/disk/by-uuid/09c38f69-dd3d-4062-ad99-c751c619cb3a";
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
      "vm.swappiness" = 10;
    };

    supportedFilesystems = [
      "btrfs"
      "vfat"
      "fuse"
      "ntfs"
      "exfat"
    ];
  };

  fileSystems = {
    "/" = {
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
    "/home" = {
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
    "/boot" = {
      device = "/dev/disk/by-uuid/5990-8457";
      fsType = "vfat";
      options = [
        "fmask=0022"
        "dmask=0022"
      ];
    };
    "/swap" = {
      device = "/dev/mapper/root";
      fsType = "btrfs";
      options = [
        "subvol=@swap"
        "noatime"
      ];
    };
    "/mnt/data" = {
      device = "/dev/mapper/data";
      fsType = "ext4";
      options = [
        "defaults"
        "noatime"
      ];
    };
  };

  swapDevices = [
    {
      device = "/swap/swapfile";
      priority = 10;
    }
  ];

  zramSwap = {
    enable = true;
    memoryPercent = 20;
    algorithm = "zstd";
  };

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
      powerManagement = {
        finegrained = false;
        enable = false;
      };
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
    thermald.enable = false;

    throttled = {
      enable = true;
      extraConfig = ''
        [GENERAL]
        Enabled: True
        Sysfs_Power_Path: /sys/class/power_supply/AC*/online
        Autoreload: True

        [BATTERY]
        Update_Rate_s: 5
        PL1_Tdp_W: 15
        PL1_Duration_s: 28
        PL2_Tdp_W: 20
        PL2_Duration_S: 0.002
        Trip_Temp_C: 80
        cTDP: 1
        Disable_BDPROCHOT: False

        [AC]
        Update_Rate_s: 1
        PL1_Tdp_W: 65
        PL1_Duration_s: 28
        PL2_Tdp_W: 80
        PL2_Duration_S: 0.002
        Trip_Temp_C: 90
        HWP_Mode: True
        cTDP: 0
        Disable_BDPROCHOT: False

        [UNDERVOLT.BATTERY]
        CORE: 0
        GPU: 0
        CACHE: 0
        UNCORE: 0
        ANALOGIO: 0

        [UNDERVOLT.AC]
        CORE: 0
        GPU: 0
        CACHE: 0
        UNCORE: 0
        ANALOGIO: 0
      '';
    };

    tlp = {
      enable = false;
      settings = {
        CPU_SCALING_MAX_FREQ_ON_AC = 4500000;
        CPU_SCALING_MIN_FREQ_ON_BAT = 800000;
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
      sensors = [
        {
          type = "hwmon";
          query = "/sys/class/hwmon";
          name = "coretemp";
          indices = [
            1
            2
            3
            4
            5
            6
            7
          ];
        }
      ];
      fans = [
        {
          type = "tpacpi";
          query = "/proc/acpi/ibm/fan";
        }
      ];
      levels = [
        [
          0
          0
          40
        ]
        [
          1
          38
          45
        ]
        [
          2
          43
          50
        ]
        [
          3
          48
          58
        ]
        [
          4
          55
          65
        ]
        [
          5
          62
          72
        ]
        [
          6
          69
          78
        ]
        [
          7
          76
          84
        ]
        [
          "level disengaged"
          82
          32767
        ]
      ];
    };

    xserver.videoDrivers = [ "nvidia" ];
  };

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
}
