{ pkgs, ... }:
{
  packages = [ pkgs.deploy-rs pkgs.openssh pkgs.secretspec pkgs.wireguard-tools ];
  tasks = {
    "pi:secrets-init".exec = "scripts/pi/secrets-init";
    "pi:key-create".exec = "scripts/pi/key-create";
    "pi:public-key".exec = "scripts/pi/public-key";
    "pi:key-inject".exec = "scripts/pi/key-inject";
    "pi:deploy-bootstrap".exec = "scripts/pi/deploy-bootstrap";
    "pi:deploy".exec = "scripts/pi/deploy";
    "pi:wireguard-deploy".exec = "scripts/pi/wireguard-deploy";
  };
}
