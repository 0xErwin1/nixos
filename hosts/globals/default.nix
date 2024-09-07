{
  nixpkgs.config.allowUnfree = true;
  imports = [
    ./locale.nix
    ./users.nix
  ];
}
