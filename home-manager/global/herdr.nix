{ pkgs, ... }:
{
  home.packages = with pkgs; [
    herdr
  ];

  xdg.configFile."herdr/config.toml" = {
    force = true;
    text = ''
      onboarding = false

      [theme]
      name = "one-dark"
      auto_switch = false

      [theme.custom]
      panel_bg = "#0A0E14"
      surface_dim = "#11151C"
      accent = "#E6B450"
      red = "#F07178"
      green = "#C3E88D"
      yellow = "#FFCB6B"
      peach = "#FF8F40"
      mauve = "#C792EA"

      [keys]
      prefix = "ctrl+a"
      new_workspace = "prefix+n"
      rename_workspace = "prefix+shift+n"
      close_workspace = "prefix+shift+d"
      reload_config = "prefix+shift+r"
      new_tab = "prefix+c"
      split_vertical = "prefix+v"
      split_horizontal = "prefix+-"
      close_pane = "prefix+x"
      fullscreen = "prefix+f"
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
      agent_panel_scope = "all"
      show_agent_labels_on_pane_borders = false
      agent_panel_sort = "priority"

      [ui.toast]
      delivery = "system"

      [ui.sound]
      enabled = false

      [experimental]
      pane_history = true
    '';
  };
}
