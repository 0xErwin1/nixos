{ pkgs, ... }:
{
  packages = [
    pkgs.deploy-rs
    pkgs.openssh
    pkgs.sops
    pkgs.wireguard-tools
  ];
  tasks = {
    "pi:deploy".exec = "scripts/pi/deploy";
  };
}
