{ pkgs, ... }:
{
  home.packages = with pkgs; [
    zed-editor
  ];

  xdg.configFile = {
    "zed/settings.json".source = ./settings.json;
    "zed/keymap.json".source = ./keymap.json;
    "zed/tasks.json".source = ./tasks.json;
  };
}
