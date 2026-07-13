{ lib, ... }:
{
  boot.initrd.availableKernelModules = [ "nvme" ];

  fileSystems = {
    "/" = {
      device = "/dev/disk/by-uuid/88e0bafc-fda9-4bb1-8a72-8847b784a016";
      fsType = "ext4";
    };
    "/boot" = {
      device = "/dev/disk/by-uuid/56AD-3F13";
      fsType = "vfat";
      options = [
        "fmask=0022"
        "dmask=0022"
      ];
    };
  };

  nixpkgs.hostPlatform = lib.mkDefault "aarch64-linux";
}
