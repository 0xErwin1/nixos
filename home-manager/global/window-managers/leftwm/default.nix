{ lib, config, ... }:
{
  options.leftwm.theme = lib.mkOption {
    type = lib.types.str;
    default = "current";
    description = "LeftWM theme directory name under themes/";
  };

  imports = [ ../../x11.nix ];

  config.home.file = {
    ".config/leftwm/config.ron".source = ./config.ron;
    ".config/leftwm/themes.toml".source = ./themes.toml;
    ".config/leftwm/themes/current".source = ./themes + "/${config.leftwm.theme}";
  };
}
