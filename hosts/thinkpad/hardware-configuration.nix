{
  pkgs,
  config,
  lib,
  modulesPath,
  ...
}:

{
  imports = [ (modulesPath + "/installer/scan/not-detected.nix") ];

  boot = {
    initrd = {
      availableKernelModules = [
        "nvme"
        "xhci_pci"
        "usbhid"
        "usb_storage"
        "sd_mod"
        "rtsx_pci_sdmmc"
      ];
      kernelModules = [ ];
      luks = {
        devices = {
          "luks-84bac843-e195-4c4e-81c2-db8d0f02acd2".device = "/dev/disk/by-uuid/84bac843-e195-4c4e-81c2-db8d0f02acd2";
          "luks-31afe9e5-0c92-4d22-8afe-d874da2c6d0c".device = "/dev/disk/by-uuid/31afe9e5-0c92-4d22-8afe-d874da2c6d0c";
        };
      };
    };
    kernelModules = [ "kvm-amd" ];
    extraModulePackages = [ ];
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
    pulseaudio.enable = false;

    cpu.amd.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;

    graphics = {
      enable = true;
      enable32Bit = true;
      extraPackages = [ pkgs.amdvlk ];
      extraPackages32 = [ pkgs.driversi686Linux.amdvlk ];
    };
  };

  networking.useDHCP = lib.mkDefault true;

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
}
