{ lib, ... }:
let
  localConfigPath = "/home/iperez/.ssh/wireguard/default.nix";
  localConfig =
    if builtins.pathExists localConfigPath
    then import localConfigPath
    else {};

  localEndpoint = localConfig.wireguardServerIP or null;
  localPrivateKeyFile = localConfig.wireguardPrivateKey or null;
  hasConfig = localEndpoint != null && localPrivateKeyFile != null;
in
{
  vault.wireguard = lib.optionalAttrs hasConfig {
    enable = true;
    privateKeyFile = localPrivateKeyFile;
    endpoint = localEndpoint;
  };
}
