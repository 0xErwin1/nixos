# Wofi styled as one more card of the Astal bar (home-manager/global/bar). The
# stylesheet belongs to the active wl-theme (home-manager/global/theme):
# style.css is an out-of-store link through the theme's state symlink, so a
# `wl-theme set` applies on the next launch without a rebuild.
#
# The shared settings stay neutral (centered, one column) because `bt-menu`
# also drives wofi in dmenu mode. The application launcher size lives in the
# `app-launcher` wrapper instead, which also closes it on a second press.
{ pkgs, config, ... }:
let
  launcherFlags = [
    "--width 560"
    "--height 520"
  ];

  mkToggle =
    name: mode: prompt:
    pkgs.writeShellScriptBin name ''
      # A second press closes the open launcher instead of stacking another.
      if ${pkgs.procps}/bin/pkill -x wofi; then
        exit 0
      fi
      exec wofi --show ${mode} --prompt "${prompt}" ${builtins.concatStringsSep " " launcherFlags}
    '';
in
{
  imports = [ ../../theme ];

  home.packages = [
    (mkToggle "app-launcher" "drun" "Search applications")
    (mkToggle "window-switcher" "window" "Switch window")
  ];

  programs.wofi = {
    enable = true;
    settings = {
      show = "drun";
      prompt = "Search";
      width = 560;
      height = 420;
      location = "center";
      allow_markup = true;
      insensitive = true;
      matching = "multi-contains";
      term = "ghostty";
      columns = 1;
      hide_scroll = true;
      allow_images = true;
      image_size = 28;
      no_actions = true;
      gtk_dark = true;
      key_expand = "Tab";
    };
  };

  xdg.configFile."wofi/style.css".source =
    config.lib.file.mkOutOfStoreSymlink "${config.xdg.stateHome}/wl-theme/current/wofi.css";
}
