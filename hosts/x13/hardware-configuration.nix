{
  config,
  lib,
  pkgs,
  modulesPath,
  ...
}:
{
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
  ];

  boot = {
    initrd = {
      availableKernelModules = [
        "xhci_pci"
        "nvme"
        "usb_storage"
        "sd_mod"
        "sdhci_pci"
      ];
      kernelModules = [ ];
      luks.devices."luks-e6ecdd7e-257e-4606-9ac1-c9aab8addce2".device =
        "/dev/disk/by-uuid/e6ecdd7e-257e-4606-9ac1-c9aab8addce2";
    };
    kernelModules = [ "kvm-intel" ];
    extraModulePackages = [ ];
    resumeDevice = "/dev/mapper/luks-e6ecdd7e-257e-4606-9ac1-c9aab8addce2";
    kernelParams = [ "resume_offset=2499291" ];
  };

  fileSystems = {
    "/" = {
      device = "/dev/mapper/luks-e6ecdd7e-257e-4606-9ac1-c9aab8addce2";
      fsType = "btrfs";
      options = [ "subvol=@" ];
    };
    "/home" = {
      device = "/dev/mapper/luks-e6ecdd7e-257e-4606-9ac1-c9aab8addce2";
      fsType = "btrfs";
      options = [ "subvol=@home" ];
    };
    "/boot" = {
      device = "/dev/disk/by-uuid/4503-017F";
      fsType = "vfat";
      options = [
        "fmask=0077"
        "dmask=0077"
      ];
    };
  };

  swapDevices = [
    {
      device = "/swap/swapfile";
    }
  ];

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  hardware = {
    cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
    bluetooth.enable = true;
  };

}
