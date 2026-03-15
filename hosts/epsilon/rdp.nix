{ ... }:
{
  services = {
    xrdp = {
      enable = true;
      openFirewall = false;
    };
    cloudflared = {
      enable = true;
      tunnels = {
        "d508b1ad-e18e-41d4-a375-1ed9ccc4c6fe" = {
          credentialsFile = "/etc/cloudflared/d508b1ad-e18e-41d4-a375-1ed9ccc4c6fe.json";
          "default" = "http_status:404";
          ingress = {
            "ssh.iperez.dev" = {
              service = "ssh://localhost:22222";
            };
          };
        };
      };
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
