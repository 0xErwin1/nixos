{
  config,
  pkgs,
  inputs,
  ...
}:
{
  home.packages = [ inputs.nixvim.packages.${pkgs.system}.default ];
}
