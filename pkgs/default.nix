# You can build them using 'nix build .#example'
{ pkgs, inputs }:
{
  nixvim = inputs.nixvim.packages.${pkgs.system};
}
