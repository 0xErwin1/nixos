{
  lib,
  wireguardLocal ? { },
  ...
}:
let
  localEndpoint = wireguardLocal.wireguardServerIP or null;
  localPrivateKeyFile = wireguardLocal.wireguardPrivateKey or null;
  localAddress = wireguardLocal.wireguardAddress or [ "10.0.0.3/24" ];
  localDns = wireguardLocal.wireguardDns or [ "10.0.0.1" "1.1.1.1" ];
  localDomain = wireguardLocal.wireguardDomain or "~iperez.dev";

  hasConfig = localEndpoint != null && localPrivateKeyFile != null;
in
{
  config = lib.mkIf hasConfig {
    vault.wireguard = {
      enable = true;
      privateKeyFile = localPrivateKeyFile;
      endpoint = localEndpoint;
      address = localAddress;
      dns = localDns;
      domain = localDomain;
    };
  };
}
