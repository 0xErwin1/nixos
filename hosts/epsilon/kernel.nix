{ pkgs, ... }:
{
  nixpkgs.overlays = [
    (self: super: {
      thinkpadKernel = super.linuxPackages_latest.kernel.override (oldAttrs: rec {
        NIX_CFLAGS_COMPILE = oldAttrs.NIX_CFLAGS_COMPILE + "-mtune=znver3 -march=znver3 -O3";
      });
    })
  ];

  boot.kernelPackages = pkgs.linuxPackagesFor pkgs.thinkpadKernel;
}
