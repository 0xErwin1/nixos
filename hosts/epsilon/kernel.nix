{ pkgs, ... }:
{
  boot = {
    kernelPackages = pkgs.linuxPackages_latest;
    plymouth.enable = true;
    kernelParams = [
      "quiet"
      "splash"
      "i915.enable_psr=0"
      "i915.enable_fbc=0"
      "i915.enable_dc=0"

      "zswap.enabled=0"

      "loglevel=3"

      "nvidia_drm.modeset=1"
      "nvidia.NVreg_DynamicPowerManagement=0x02"

      "resume_offset=98213725"
    ];

    resumeDevice = "/dev/mapper/root";

    blacklistedKernelModules = [ "nouveau" ];
  };
}
