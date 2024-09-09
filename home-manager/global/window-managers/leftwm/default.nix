{config, ...}: {
  imports = [ ./dependencies.nix ];

  home = {
    file = {
      ".config/leftwm/config.ron".source = ./config.ron;
      ".config/leftwm/themes.toml".source = ./themes.toml;
      ".config/leftwm/themes".source = ./themes;
    };
  };
}
