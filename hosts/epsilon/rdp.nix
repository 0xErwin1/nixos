{ pkgs, ... }:
{
  services.xrdp = {
    enable = true;
    defaultWindowManager = "${pkgs.leftwm}/bin/leftwm";

    # Firewall is managed manually below to restrict access by source.
    openFirewall = false;
  };

  # cloudflared tunnel exposes xrdp to Cloudflare Access without opening the
  # port to the internet. The tunnel token is read from a file outside the Nix
  # store so it is never committed to the repo.
  #
  # Setup (once, on epsilon):
  #   sudo mkdir -p /etc/cloudflared
  #   echo "CLOUDFLARED_TOKEN=<your-token>" | sudo tee /etc/cloudflared/rdp.env
  #   sudo chmod 600 /etc/cloudflared/rdp.env
  #
  # The tunnel itself (with the TCP ingress rule pointing to localhost:3389)
  # must be created in the Cloudflare dashboard first.
  systemd.services.cloudflared-rdp = {
    description = "Cloudflare Tunnel — RDP";
    after = [
      "network-online.target"
      "xrdp.service"
    ];
    wants = [ "network-online.target" ];
    wantedBy = [ "multi-user.target" ];

    serviceConfig = {
      Type = "simple";
      EnvironmentFile = "/etc/cloudflared/rdp.env";
      ExecStart = "${pkgs.cloudflared}/bin/cloudflared tunnel --no-autoupdate run --token \${CLOUDFLARED_TOKEN}";
      Restart = "on-failure";
      RestartSec = "5s";
      DynamicUser = true;
    };
  };

  # Allow RDP from:
  #   - WireGuard / LAN (direct IP access)
  #   - 127.0.0.1 (cloudflared tunnel proxy)
  networking.firewall.extraCommands = ''
    iptables -A INPUT -p tcp --dport 3389 -s 127.0.0.1 -j ACCEPT
    iptables -A INPUT -p tcp --dport 3389 -s 10.0.0.0/8 -j ACCEPT
    iptables -A INPUT -p tcp --dport 3389 -s 192.168.0.0/16 -j ACCEPT
    iptables -A INPUT -p tcp --dport 3389 -j DROP
  '';

  networking.firewall.extraStopCommands = ''
    iptables -D INPUT -p tcp --dport 3389 -s 127.0.0.1 -j ACCEPT || true
    iptables -D INPUT -p tcp --dport 3389 -s 10.0.0.0/8 -j ACCEPT || true
    iptables -D INPUT -p tcp --dport 3389 -s 192.168.0.0/16 -j ACCEPT || true
    iptables -D INPUT -p tcp --dport 3389 -j DROP || true
  '';
}
