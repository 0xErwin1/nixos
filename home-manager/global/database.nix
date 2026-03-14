{ pkgs, inputs, ... }:
{
  home.packages = with pkgs; [
    dbeaver-bin
    inputs.dbflux.packages.${pkgs.system}.default
  ];
}
