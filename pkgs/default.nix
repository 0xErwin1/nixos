{ pkgs, inputs }:
{
  nixvim = inputs.nixvim.packages.${pkgs.system};
}
