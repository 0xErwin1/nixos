{
  lib,
  ...
}:

{
  hardware = {
    pulseaudio.enable = false;
  };

  boot = {
    initrd = {
      availableKernelModules = [
        "ahci"
        "xhci_pci"
        "virtio_pci"
        "sr_mod"
        "virtio_blk"
      ];
      kernelModules = [ ];
      luks.devices."luks-724ff31c-dd3d-448f-a917-1102fbcf8b33".device = "/dev/disk/by-uuid/724ff31c-dd3d-448f-a917-1102fbcf8b33";
    };
    kernelModules = [ "kvm-amd" ];
    extraModulePackages = [ ];
  };

  fileSystems."/" = {
    device = "/dev/disk/by-uuid/ded0d47f-e726-451b-b56f-7c676849169f";
    fsType = "ext4";
  };

  fileSystems."/boot" = {
    device = "/dev/disk/by-uuid/83F8-4A10";
    fsType = "vfat";
    options = [
      "fmask=0022"
      "dmask=0022"
    ];
  };

  swapDevices = [ ];

  networking.useDHCP = lib.mkDefault true;

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
}
