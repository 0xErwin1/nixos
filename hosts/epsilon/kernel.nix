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
      # The external monitor (DP-1) is wired to the NVIDIA GPU. Dynamic runtime
      # power management (0x02) lets the GPU suspend when idle, which races with
      # the compositor on hotplug and crashes Hyprland when DP-1 is unplugged.
      # 0x00 keeps the GPU powered so connector removal stays stable.
      "nvidia.NVreg_DynamicPowerManagement=0x00"

      "resume_offset=98213725"
    ];

    resumeDevice = "/dev/mapper/root";

    blacklistedKernelModules = [ "nouveau" ];
  };
}
