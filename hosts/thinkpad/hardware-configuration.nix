{
  pkgs,
  config,
  lib,
  modulesPath,
  ...
}:
let
  wireguardConfig = import /etc/wireguard;
in
{
  imports = [
    ./kernel.nix
    (modulesPath + "/installer/scan/not-detected.nix") 
  ];

  boot = {
    initrd = {
      availableKernelModules = [
        "nvme"
        "xhci_pci"
        "usbhid"
        "usb_storage"
        "sd_mod"
        "rtsx_pci_sdmmc"
        "amdgpu"
      ];
      kernelModules = [ ];
      luks = {
        devices = {
          "luks-84bac843-e195-4c4e-81c2-db8d0f02acd2".device =
            "/dev/disk/by-uuid/84bac843-e195-4c4e-81c2-db8d0f02acd2";
          "luks-31afe9e5-0c92-4d22-8afe-d874da2c6d0c".device =
            "/dev/disk/by-uuid/31afe9e5-0c92-4d22-8afe-d874da2c6d0c";
        };
      };
    };
    kernelModules = [
      "kvm-amd"
      "thinkpad_acpi"
      "fuse"
      "amdgpu"
    ];
    extraModulePackages = [ ];
    blacklistedKernelModules = [ "pcspkr" ];
    extraModprobeConfig = ''
      options thinkpad_acpi fan_control=1
    '';
    supportedFilesystems = [
      "ext4"
      "vfat"
      "fuse"
      "ntfs"
      "exfat"
    ];
  };

  fileSystems."/" = {
    device = "/dev/disk/by-uuid/54d4d00a-b8ef-4e67-a65e-a107773569cc";
    fsType = "ext4";
  };

  fileSystems."/boot" = {
    device = "/dev/disk/by-uuid/C666-5D4A";
    fsType = "vfat";
    options = [
      "fmask=0077"
      "dmask=0077"
    ];
  };

  swapDevices = [ { device = "/dev/disk/by-uuid/85405fdd-64f3-4889-b5e5-ea5fd9ccfa8c"; } ];

  hardware = {
    bluetooth = {
      enable = true;
    };

    cpu.amd.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;

    graphics = {
      enable = true;
      enable32Bit = true;
      extraPackages = with pkgs; [
        amdvlk
        libva-utils
        clinfo
      ];
      extraPackages32 = [ pkgs.driversi686Linux.amdvlk ];
    };
  };

  networking = {
    useDHCP = lib.mkDefault true;
    firewall.allowedTCPPorts = [ 51820 ];
    wg-quick.interfaces = {
      wg0 = {
        address = [ "10.0.0.3/24" ];
        dns = [ "10.0.0.1" ];
        listenPort = 51820;
        privateKeyFile = wireguardConfig.wireguardPrivateKey;
        peers = [
          {
            publicKey = "wZBcXWnY+1i67PHLBqes/x5U920dJhtJ7i1RFPhiIDQ=";
            allowedIPs = [
              "10.0.0.0/24"
              "10.0.1.0/24"
            ];
            endpoint = wireguardConfig.wireguardServerIP;
            persistentKeepalive = 25;
          }
        ];
      };
    };
  };

  services = {
    fwupd.enable = true;
    tlp = {
      enable = true;
      settings = {
        CPU_SCALING_GOVERNOR_ON_AC = "performance";
        CPU_SCALING_GOVERNOR_ON_BAT = "powersave";

        CPU_ENERGY_PERF_POLICY_ON_BAT = "power";
        CPU_ENERGY_PERF_POLICY_ON_AC = "performance";

        CPU_MIN_PERF_ON_AC = 0;
        CPU_MAX_PERF_ON_AC = 100;
        CPU_MIN_PERF_ON_BAT = 0;
        CPU_MAX_PERF_ON_BAT = 20;

        START_CHARGE_THRESH_BAT0 = 40;
        STOP_CHARGE_THRESH_BAT0 = 80;

        RADEON_DPM_STATE_ON_AC = "performance";
        RADEON_DPM_STATE_ON_BAT = "powersave";
      };
    };
    fprintd = {
      enable = true;
      tod = {
        enable = true;
        driver = pkgs.libfprint-2-tod1-vfs0090;
      };
    };

    thinkfan = {
      enable = true;
      smartSupport = true;
    };
    xserver = {
      enable = true;
      videoDrivers = [ "amdgpu" ];
    };
    clamav = {
      scanner = {
        enable = false;
      };
      daemon = {
        enable = false;
        settings = {
          MaxThreads = 1;
          LogSyslog = true;
        };
      };
      fangfrisch.enable = true;
      updater = {
        enable = false;
      };
    };
  };

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
}
