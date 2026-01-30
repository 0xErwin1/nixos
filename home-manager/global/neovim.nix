{
  pkgs,
  inputs,
  ...
}:
{
  home.packages = [
    inputs.nixvim.packages.${pkgs.stdenv.hostPlatform.system}.personal
  ];
}
