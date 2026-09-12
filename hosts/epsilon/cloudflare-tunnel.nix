{ pkgs, ... }:
{

  environment.systemPackages = [ pkgs.cloudflare-warp ];
  systemd.packages = [ pkgs.cloudflare-warp ];
  systemd.services.warp-svc.enable = true;

  # warp-svc 2026.7 applies its firewall rules by executing the absolute path
  # /usr/sbin/nft, which no PATH wrapper can redirect and which NixOS does not
  # provide. Without this symlink every connect fails with FirewallUpdateFailed.
  systemd.tmpfiles.rules = [
    "d /usr/sbin 0755 root root -"
    "L+ /usr/sbin/nft - - - - ${pkgs.nftables}/bin/nft"
  ];

  services.cloudflared = {
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
}
