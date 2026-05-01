{ pkgs, ... }:
{
  nixpkgs.config.allowUnfree = true;
  imports = [
    ./locale.nix
    ./users.nix
  ];
  # Disabled for performance - run 'nix-store --optimise' manually when needed
  nix.settings.auto-optimise-store = false;

  environment.systemPackages = with pkgs; [
    usbutils
    python3Packages.uv
  ];
  services.udisks2.enable = true;

  # Many scripts hardcode /bin/bash; NixOS only provides /bin/sh by default.
  system.activationScripts.binbash = ''
    ln -sf ${pkgs.bash}/bin/bash /bin/bash
  '';
}
