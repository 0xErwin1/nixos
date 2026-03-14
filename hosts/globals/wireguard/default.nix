{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.vault.wireguard;
in
{
  options.vault.wireguard = {
    enable = lib.mkEnableOption "WireGuard wg0 tunnel";

    privateKeyFile = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
    };

    endpoint = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
    };

    address = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ "10.0.0.3/24" ];
    };

    dns = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [
        "10.0.0.1"
        "1.1.1.1"
      ];
    };

    domain = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = "~iperez.dev";
    };
  };

  config = {
    assertions = [
      {
        assertion = (!cfg.enable) || (cfg.privateKeyFile != null && cfg.endpoint != null);
        message = "vault.wireguard.enable is true, but vault.wireguard.privateKeyFile and/or vault.wireguard.endpoint are not set.";
      }
    ];

    services = {
      resolved = {
        enable = lib.mkIf cfg.enable true;
        fallbackDns = [
          "1.1.1.1"
          "1.0.0.1"
        ];
      };
    };

    networking.firewall.allowedUDPPorts = [ 51820 ];

    networking.wg-quick.interfaces.wg0 =
      lib.mkIf (cfg.enable && cfg.privateKeyFile != null && cfg.endpoint != null)
        {
          inherit (cfg) address;
          listenPort = 51820;
          mtu = 1300;
          inherit (cfg) privateKeyFile;

          peers = [
            {
              publicKey = "wZBcXWnY+1i67PHLBqes/x5U920dJhtJ7i1RFPhiIDQ=";
              inherit (cfg) endpoint;
              allowedIPs = [
                "10.0.0.0/24"
                "10.0.1.0/24"
              ];
              persistentKeepalive = 25;
            }
          ];

          postUp = ''
            ${pkgs.systemd}/bin/resolvectl dns wg0 ${lib.concatStringsSep " " cfg.dns}
            ${lib.optionalString (cfg.domain != null) ''
              ${pkgs.systemd}/bin/resolvectl domain wg0 '${cfg.domain}'
            ''}
          '';

          preDown = ''
            ${pkgs.systemd}/bin/resolvectl revert wg0
          '';
        };
  };
}
