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
    upower
  ];
}
