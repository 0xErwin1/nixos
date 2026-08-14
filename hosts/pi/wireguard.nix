{ config, ... }:
{
  networking.wg-quick.interfaces.wg0 = {
    address = [ "10.0.0.2/24" ];
    dns = [
      "10.0.0.1"
      "1.1.1.1"
    ];
    listenPort = 51820;
    mtu = 1300;
    privateKeyFile = config.sops.secrets."pi/wireguard-private-key".path;
    peers = [
      {
        publicKey = "wZBcXWnY+1i67PHLBqes/x5U920dJhtJ7i1RFPhiIDQ=";
        endpoint = "142.44.162.92:51820";
        allowedIPs = [
          "10.0.0.0/24"
          "10.0.1.0/24"
        ];
        persistentKeepalive = 25;
      }
    ];
  };

  networking.firewall.trustedInterfaces = [ "wg0" ];

  systemd.services.wg-quick-wg0 = {
    after = [ "sops-install-secrets.service" ];
    requires = [ "sops-install-secrets.service" ];
  };
}
