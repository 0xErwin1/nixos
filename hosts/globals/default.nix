{ pkgs, ... }:
{
  nixpkgs.config.allowUnfree = true;
  imports = [
    ./locale.nix
    ./users.nix
  ];
  nix.settings.auto-optimise-store = true;

  environment.systemPackages = with pkgs; [
    usbutils
    python3Packages.uv
  ];
}
