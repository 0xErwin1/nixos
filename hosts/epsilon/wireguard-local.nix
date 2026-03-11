{
  lib,
  wireguardLocal ? { },
  ...
}:
let
  localEndpoint = wireguardLocal.wireguardServerIP or null;
  localPrivateKeyFile = wireguardLocal.wireguardPrivateKey or null;
  hasConfig = localEndpoint != null && localPrivateKeyFile != null;
in
{
  config = lib.mkIf hasConfig {
    vault.wireguard = {
      enable = true;
      privateKeyFile = localPrivateKeyFile;
      endpoint = localEndpoint;
    };
  };
}
