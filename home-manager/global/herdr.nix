{ pkgs, lib, config, ... }:
let
  palettes = import ./theme/palettes.nix;

  # Everything that does not depend on the palette. Herdr has no include, so
  # each theme gets a complete config: this base plus its own [theme] block.
  base = ''
    onboarding = false

    [keys]
    prefix = "ctrl+a"
    new_workspace = "prefix+n"
    rename_workspace = "prefix+shift+n"
    close_workspace = "prefix+shift+d"
    reload_config = "prefix+shift+r"
    new_tab = "prefix+c"
    split_vertical = "prefix+v"
    split_horizontal = "prefix+minus"
    close_pane = "prefix+x"
    zoom = "prefix+f"
    resize_mode = "prefix+r"
    toggle_sidebar = "prefix+b"
    previous_workspace = "ctrl+shift+k"
    next_workspace = "ctrl+shift+j"
    previous_tab = "alt+h"
    next_tab = "alt+l"
    focus_pane_left = "ctrl+alt+h"
    focus_pane_down = "ctrl+alt+j"
    focus_pane_up = "ctrl+alt+k"
    focus_pane_right = "ctrl+alt+l"

    [ui]
    show_agent_labels_on_pane_borders = false
    agent_panel_sort = "priority"

    [ui.toast]
    delivery = "system"

    [ui.sound]
    enabled = false

    [experimental]
    pane_history = true
  '';

  # Herdr lives inside a terminal, so the surfaces come from the terminal
  # palette and the accents from the desktop one. The built-in name only fills
  # the tokens not overridden here.
  themeBlock =
    p:
    let
      t = p.terminal;
    in
    ''
      [theme]
      name = "${if p.mode == "light" then "catppuccin-latte" else "catppuccin-mocha"}"
      auto_switch = false

      [theme.custom]
      panel_bg = "${t.background}"
      sidebar_bg = "${p.panel}"
      active_row_bg = "${p.grey}"
      selection_bg = "${p.grey}"
      surface0 = "${p.panel}"
      surface1 = "${p.grey}"
      surface_dim = "${p.line}"
      overlay0 = "${p.muted}"
      overlay1 = "${p.line}"
      text = "${t.foreground}"
      subtext0 = "${p.muted}"
      accent = "${p.yellow}"
      mauve = "${p.cyan}"
      green = "${p.green}"
      yellow = "${p.yellow}"
      red = "${p.red}"
      blue = "${p.blue}"
      teal = "${p.green}"
      peach = "${p.orange}"
    '';

  themeFiles = lib.mapAttrsToList (id: p: {
    "wl-theme/themes/${id}/herdr.toml".text = base + themeBlock p;
  }) palettes.themes;

  defaultConfig = base + themeBlock palettes.themes.${palettes.default};
in
{
  home.packages = with pkgs; [
    herdr
  ];

  # `wl-theme set` rewrites the state link and calls `herdr server reload-config`
  # (theme/wl-theme.nix), so a running client picks up the new theme.
  xdg.configFile = lib.mkMerge (
    themeFiles
    ++ [
      (
        if config.local.wlTheme.enable then
          {
            "herdr/config.toml".source = config.lib.file.mkOutOfStoreSymlink (
              "${config.xdg.stateHome}/wl-theme/current/herdr.toml"
            );
          }
        else
          {
            "herdr/config.toml".text = defaultConfig;
          }
      )
    ]
  );
}
