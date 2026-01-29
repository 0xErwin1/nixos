{ config, lib, ... }:
let
  cfg = config.homme.wireguard;
in
{
  options.homme.wireguard = {
    enable = lib.mkEnableOption "WireGuard wg0 tunnel";

    privateKeyFile = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      description = ''
        Path to the wg0 private key file.

        Use an absolute path like /etc/wireguard/wg0.key to keep secrets out of the Nix store.
        This module does not read the file at evaluation time.
      '';
      example = "/etc/wireguard/wg0.key";
    };

    endpoint = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      description = "WireGuard peer endpoint in host:port form.";
      example = "vpn.example.com:51820";
    };
  };

  config = {
    assertions = [
      {
        assertion = (!cfg.enable) || (cfg.privateKeyFile != null && cfg.endpoint != null);
        message = "homme.wireguard.enable is true, but homme.wireguard.privateKeyFile and/or homme.wireguard.endpoint are not set.";
      }
    ];

    networking = lib.mkIf (cfg.enable && cfg.privateKeyFile != null && cfg.endpoint != null) {
      firewall.allowedUDPPorts = [ 51820 ];
      wg-quick.interfaces.wg0 = {
        address = [ "10.0.0.3/24" ];
        dns = [ "10.0.0.1" ];
        listenPort = 51820;
        privateKeyFile = cfg.privateKeyFile;
        peers = [
          {
            publicKey = "wZBcXWnY+1i67PHLBqes/x5U920dJhtJ7i1RFPhiIDQ=";
            allowedIPs = [
              "10.0.0.0/24"
              "10.0.1.0/24"
            ];
            endpoint = cfg.endpoint;
            persistentKeepalive = 25;
          }
        ];
      };
    };
  };
}
