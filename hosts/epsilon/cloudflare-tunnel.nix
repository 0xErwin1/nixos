{ ... }:
{
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
