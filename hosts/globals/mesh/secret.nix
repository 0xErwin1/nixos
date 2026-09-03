{ config, ... }:
{
  # One reusable pre-auth key shared by every node, kept in secrets/mesh.yaml.
  # Rotating it restarts tailscaled so the enrolment unit re-runs with the new
  # value.
  sops.secrets."tailscale-auth-key" = {
    sopsFile = ../../../secrets/mesh.yaml;
    owner = "root";
    group = "root";
    mode = "0400";
    restartUnits = [ "tailscaled.service" ];
  };

  vault.mesh = {
    enable = true;
    authKeyFile = config.sops.secrets."tailscale-auth-key".path;
  };
}
