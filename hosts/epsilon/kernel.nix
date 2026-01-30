{ pkgs, config, ... }:
{
  boot.kernelPackages = pkgs.linuxPackages_latest;

  boot.kernelParams = [
    # Intel graphics - disabled to avoid flickering/issues
    "i915.enable_psr=0"
    "i915.enable_fbc=0"
    "i915.enable_dc=0"

    # zswap disabled (using zram instead)
    "zswap.enabled=0"

    # Quiet boot
    "loglevel=3"

    # NVIDIA
    "nvidia_drm.modeset=1"
    "nvidia.NVreg_DynamicPowerManagement=0x02"

    # Hibernation (resume from BTRFS swapfile)
    "resume_offset=98213725"
  ];

  # Resume device for hibernation
  boot.resumeDevice = "/dev/mapper/root";

  boot.blacklistedKernelModules = [ "nouveau" ];
}
