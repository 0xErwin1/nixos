{
  nixpkgs.config.allowUnfree = true;
  imports = [
    ./locale.nix
    ./users.nix
  ];
  nix.settings.auto-optimise-store = true;
}
