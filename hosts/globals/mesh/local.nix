{
  lib,
  meshLocal ? { },
  ...
}:
let
  localAuthKeyFile = meshLocal.meshAuthKeyFile or null;
in
{
  config = lib.mkIf (localAuthKeyFile != null) {
    vault.mesh = {
      enable = true;
      authKeyFile = localAuthKeyFile;
    };
  };
}
