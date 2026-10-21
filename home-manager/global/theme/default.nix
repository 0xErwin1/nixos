# Runtime-switchable desktop theme (Ayu / Byzantium, dark / light).
#
# Every theme gets its assets under `~/.config/wl-theme/themes/<id>/`; the
# active one is the symlink `<stateHome>/wl-theme/current` managed by
# `wl-theme set <id>`. Hyprland and hyprlock `source` their theme file through
# that link and wofi's style.css points at it, so the choice survives Home
# Manager switches, `hyprctl reload` and reboots without any rebuild. The bar
# bundles the CSS of every theme, applies the active one itself and watches the
# link, so a switch from a terminal or keybind reaches it too.
#
# When the profile manages GTK (themes.nix), every theme also carries a
# `dconf.ini` with its `org.gnome.desktop.interface` color scheme, GTK theme and
# icon theme. `wl-theme set` loads it into dconf, and activation reapplies the
# persisted theme's file after Home Manager's own dconf step, so GTK, libadwaita
# and portal-aware apps follow the theme's mode.
{
  pkgs,
  lib,
  config,
  ...
}:
let
  palettes = import ./palettes.nix;

  hex = lib.removePrefix "#";

  wl-theme = import ./wl-theme.nix { inherit pkgs lib config; };

  stateDir = "${config.xdg.stateHome}/wl-theme";
  themesDir = "${config.xdg.configHome}/wl-theme/themes";

  hyprlandConf = p: ''
    general {
        col.active_border = rgb(${hex p.yellow})
        col.inactive_border = rgb(${hex p.line})
    }
  '';

  # hyprlang variables consumed by hyprlock.nix; rgba(RRGGBBAA) form. The
  # wallpaper is not themed, so the text gets a halo in the theme's background
  # color, and light themes, whose text is dark, get an almost opaque field.
  hyprlockConf = p: ''
    $wl_text = rgba(${hex p.foreground}ff)
    $wl_text_soft = rgba(${hex p.foreground}e6)
    $wl_text_dim = rgba(${hex p.foreground}bf)
    $wl_accent = rgba(${hex p.yellow}ff)
    $wl_field = rgba(${hex p.background}${if p.mode == "light" then "e6" else "33"})
    $wl_shadow = rgba(${hex p.background}${if p.mode == "light" then "ff" else "cc"})
  '';

  # dconf keyfile loaded by `wl-theme set` and by activation; GVariant strings.
  dconfIni = p: ''
    [org/gnome/desktop/interface]
    color-scheme='prefer-${p.mode}'
    gtk-theme='${if p.mode == "light" then "adw-gtk3" else "adw-gtk3-dark"}'
    icon-theme='${if p.mode == "light" then "Papirus-Light" else "Papirus-Dark"}'
  '';

  # GTK3 CSS, styled as one more card of the bar: same palette, font, radius
  # and border as `.dashboard-card`. The window itself stays transparent so the
  # rounded corners of #outer-box are not painted over by a square window
  # background.
  wofiCss = p: ''
    @define-color background ${p.background};
    @define-color foreground ${p.foreground};
    @define-color grey ${p.grey};
    @define-color yellow ${p.yellow};
    @define-color nix ${p.nix};
    @define-color overlay ${p.overlay};

    * {
      font-family: "JetBrainsMono Nerd Font";
      /* Same size as the bar's 1rem (the 12pt GTK font). */
      font-size: 12pt;
      outline: none;
    }

    window {
      background-color: transparent;
    }

    #outer-box {
      background-color: @background;
      color: @foreground;
      border: 1px solid @grey;
      border-radius: 18px;
      padding: 14px;
    }

    /* The border is always there and only changes color: a border that
       appears with focus resizes the field and shifts the whole list. */
    #input {
      margin-bottom: 10px;
      padding: 8px 14px;
      border: 1px solid transparent;
      border-radius: 999px;
      background-color: @grey;
      color: @foreground;
      box-shadow: none;
      caret-color: @yellow;
    }

    #input:focus {
      border-color: alpha(@yellow, 0.35);
    }

    /* Keep the look when the layer loses keyboard focus instead of falling
       back to the GTK theme's dimmed backdrop state. */
    #input:backdrop {
      background-color: @grey;
      color: @foreground;
    }

    #img:backdrop {
      -gtk-icon-effect: none;
      opacity: 1;
    }

    #input image {
      color: @nix;
    }

    #scroll,
    #inner-box {
      background-color: transparent;
    }

    /* GTK draws a dashed undershoot line at the scroll edge otherwise. */
    #scroll undershoot,
    #scroll overshoot {
      background: none;
    }

    #entry {
      padding: 6px 10px;
      margin: 1px 0;
      border-radius: 12px;
      background-color: transparent;
      transition: background-color 120ms ease;
    }

    #entry:hover {
      background-color: alpha(@overlay, 0.06);
    }

    #entry:selected {
      background-color: @grey;
    }

    #entry:selected #text {
      color: @yellow;
      font-weight: bold;
    }

    #img {
      margin-right: 10px;
    }

    #text {
      color: @foreground;
    }
  '';

  kittyConf =
    p:
    let
      t = p.terminal;
    in
    ''
      background ${t.background}
      foreground ${t.foreground}
      cursor ${t.cursor}
      selection_background ${t.selection-background}
      selection_foreground ${t.selection-foreground}
      url_color ${t.url}

      active_tab_foreground ${t.foreground}
      active_tab_background ${t.background}
      inactive_tab_foreground ${builtins.elemAt t.ansi 8}
      inactive_tab_background ${t.background}

      ${lib.concatImapStringsSep "\n" (i: c: "color${toString (i - 1)} ${c}") t.ansi}
    '';

  # Sourced by the tmux theme script (tmux.nix); `ayu_on` is the text drawn on
  # green and yellow fills.
  tmuxColors = p: ''
    ayu_black="${p.background}"
    ayu_on="${p.on-accent}"
    ayu_blue="${p.blue}"
    ayu_yellow="${p.yellow}"
    ayu_red="${p.red}"
    ayu_white="${p.foreground}"
    ayu_green="${p.green}"
    ayu_visual_grey="${p.grey}"
    ayu_comment_grey="${p.muted}"
  '';

  zathuraColors = p: ''
    set notification-error-bg       "${p.red}"
    set notification-error-fg       "${p.background}"
    set notification-warning-bg     "${p.orange}"
    set notification-warning-fg     "${p.background}"
    set notification-bg             "${p.background}"
    set notification-fg             "${p.foreground}"
    set completion-bg               "${p.background}"
    set completion-fg               "${p.muted}"
    set completion-group-bg         "${p.background}"
    set completion-group-fg         "${p.muted}"
    set completion-highlight-bg     "${p.grey}"
    set completion-highlight-fg     "${p.foreground}"
    set index-bg                    "${p.background}"
    set index-fg                    "${p.foreground}"
    set index-active-bg             "${p.grey}"
    set index-active-fg             "${p.foreground}"
    set inputbar-bg                 "${p.background}"
    set inputbar-fg                 "${p.foreground}"
    set statusbar-bg                "${p.background}"
    set statusbar-fg                "${p.foreground}"
    set highlight-color             "${p.blue}"
    set highlight-active-color      "${p.red}"
    set default-bg                  "${p.background}"
    set default-fg                  "${p.foreground}"
    set render-loading-fg           "${p.background}"
    set render-loading-bg           "${p.foreground}"
    set recolor-lightcolor          "${p.background}"
    set recolor-darkcolor           "${p.foreground}"
  '';

  themeFiles =
    id: p:
    {
      "wl-theme/themes/${id}/hyprland.conf".text = hyprlandConf p;
      "wl-theme/themes/${id}/hyprlock.conf".text = hyprlockConf p;
      "wl-theme/themes/${id}/wofi.css".text = wofiCss p;
      "wl-theme/themes/${id}/kitty.conf".text = kittyConf p;
      "wl-theme/themes/${id}/tmux.sh".text = tmuxColors p;
      "wl-theme/themes/${id}/zathurarc".text = zathuraColors p;
    }
    // lib.optionalAttrs config.gtk.enable {
      "wl-theme/themes/${id}/dconf.ini".text = dconfIni p;
    };
in
{
  home.packages = [ wl-theme ];

  xdg.configFile = lib.mkMerge (lib.mapAttrsToList themeFiles palettes.themes);

  # Runs before linkGeneration: Hyprland watches its config and reloads as soon
  # as the new hyprland.conf is linked, so the `source`d link has to exist by
  # then. On a first activation it dangles until linkGeneration creates the
  # theme directory. `-e` follows the link: a missing or dangling choice falls
  # back to the default, a valid one is left alone.
  home.activation.wlTheme = lib.hm.dag.entryBetween [ "linkGeneration" ] [ "writeBoundary" ] ''
    if [ ! -e ${lib.escapeShellArg "${stateDir}/current"} ]; then
      run mkdir -p ${lib.escapeShellArg stateDir}
      run ln -sfn ${lib.escapeShellArg "${themesDir}/${palettes.default}"} ${lib.escapeShellArg "${stateDir}/current"}
    fi
  '';

  # After dconfSettings: its cleanup resets keys that left `dconf.settings`, and
  # its load writes whatever the GTK module still declares. After linkGeneration:
  # the theme's dconf.ini only exists once the generation is linked. The bus
  # handling mirrors dconfSettings so a switch from a TTY still persists it.
  home.activation.wlThemeGtk = lib.mkIf config.gtk.enable (
    lib.hm.dag.entryAfter [ "dconfSettings" "linkGeneration" "wlTheme" ] ''
      if [ -e ${lib.escapeShellArg "${stateDir}/current/dconf.ini"} ]; then
        if [[ -v DBUS_SESSION_BUS_ADDRESS ]]; then
          wlThemeDbus=""
        else
          wlThemeDbus="${pkgs.dbus}/bin/dbus-run-session --dbus-daemon=${pkgs.dbus}/bin/dbus-daemon"
        fi

        run $wlThemeDbus ${pkgs.dconf}/bin/dconf load / < ${lib.escapeShellArg "${stateDir}/current/dconf.ini"} ||
          warnEcho "wl-theme: could not apply the GTK settings of the active theme"

        unset wlThemeDbus
      fi
    ''
  );
}
