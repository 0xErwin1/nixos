{ pkgs, lib, config, ... }:
let
  palettes = import ../theme/palettes.nix;

  # `settings.json` is the source of truth for every key; only `theme` is
  # replaced per desktop theme, so family and mode follow `wl-theme`.
  baseSettings = builtins.fromJSON (builtins.readFile ./settings.json);

  settingsWithoutTheme = builtins.removeAttrs baseSettings [ "theme" ];

  # Zed bundles the One, Ayu and Gruvbox families; Byzantium has no matching
  # built-in, so both families map onto the closest bundled theme.
  zedTheme =
    p:
    if p.family == "ayu" then
      (if p.mode == "dark" then "Ayu Mirage" else "Ayu Light")
    else
      (if p.mode == "dark" then "One Dark" else "One Light");

  themeFiles = lib.mapAttrsToList (id: p: {
    "wl-theme/themes/${id}/zed-settings.json".text = builtins.toJSON (
      settingsWithoutTheme // { theme = zedTheme p; }
    );
  }) palettes.themes;

  staticFiles = {
    "zed/keymap.json".source = ./keymap.json;
    "zed/tasks.json".source = ./tasks.json;
  };

  # Zed re-reads `settings.json` when it changes, so a theme switch reaches the
  # next Zed window; the file is generated from ./settings.json.
  settingsFile =
    if config.local.wlTheme.enable then
      {
        "zed/settings.json".source = config.lib.file.mkOutOfStoreSymlink (
          "${config.xdg.stateHome}/wl-theme/current/zed-settings.json"
        );
      }
    else
      {
        "zed/settings.json".text = builtins.toJSON baseSettings;
      };
in
{
  home.packages = [
    pkgs.zed-editor
  ];

  xdg.configFile = lib.mkMerge (themeFiles ++ [ staticFiles settingsFile ]);
}
