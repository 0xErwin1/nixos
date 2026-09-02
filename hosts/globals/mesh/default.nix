{ config, lib, ... }:
let
  cfg = config.vault.mesh;
in
{
  options.vault.mesh = {
    enable = lib.mkEnableOption "headscale-coordinated Tailscale mesh node";

    authKeyFile = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      description = "Path to the pre-auth key, readable by root at runtime.";
    };

    controlUrl = lib.mkOption {
      type = lib.types.str;
      default = "https://hs.iperez.dev";
    };
  };

  config = {
    assertions = [
      {
        assertion = (!cfg.enable) || cfg.authKeyFile != null;
        message = "vault.mesh.enable is true, but vault.mesh.authKeyFile is not set.";
      }
    ];

    # MagicDNS and the split zone for iperez.dev are handed to systemd-resolved
    # by tailscaled; without resolved the client rewrites resolv.conf instead.
    services.resolved.enable = lib.mkIf cfg.enable true;

    # The two VPS advertise their service addresses as /32 routes; on Linux
    # they are only installed when the client accepts routes.
    services.tailscale = lib.mkIf cfg.enable {
      enable = true;
      openFirewall = true;
      useRoutingFeatures = "client";
      authKeyFile = cfg.authKeyFile;
      extraUpFlags = [
        "--login-server=${cfg.controlUrl}"
        "--accept-routes"
      ];
    };
  };
}
