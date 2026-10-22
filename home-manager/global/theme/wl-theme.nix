# `wl-theme`: switches the active desktop theme at runtime.
#
# The active theme is one symlink, `<stateHome>/wl-theme/current`, pointing at
# `<configHome>/wl-theme/themes/<id>`. Hyprland and hyprlock `source` files
# through it, wofi's style.css, kitty's include, ghostty's config-file and
# herdr's config.toml resolve through it, and zathura, tmux, rmpc and Zed read
# the live theme file from it; Hyprland's borders, kitty, tmux and herdr are
# also updated in place. The paths are baked in at build time so the script and
# the configs can never disagree about where the link lives.
{
  pkgs,
  lib,
  config,
}:
let
  palettes = import ./palettes.nix;

  ids = builtins.attrNames palettes.themes;

  hex = lib.removePrefix "#";

  stateDir = "${config.xdg.stateHome}/wl-theme";
  themesDir = "${config.xdg.configHome}/wl-theme/themes";

  borderCase =
    id:
    let
      p = palettes.themes.${id};
    in
    ''
      ${id})
        active=${hex p.yellow}
        inactive=${hex p.line}
        ;;
    '';
in
pkgs.writeShellApplication {
  name = "wl-theme";

  runtimeInputs = [
    pkgs.coreutils
    pkgs.dconf
    pkgs.procps
  ];

  text = ''
    state_dir=${lib.escapeShellArg stateDir}
    themes_dir=${lib.escapeShellArg themesDir}

    usage() {
      echo "usage: wl-theme set <id> | get" >&2
      echo "themes: ${lib.concatStringsSep " " ids}" >&2
    }

    case "''${1:-}" in
      get)
        if [ -e "$state_dir/current" ]; then
          basename "$(readlink "$state_dir/current")"
        else
          echo ${palettes.default}
        fi
        ;;

      set)
        id="''${2:-}"

        case "$id" in
        ${lib.concatMapStrings borderCase ids}
          *)
            echo "wl-theme: unknown theme '$id'" >&2
            usage
            exit 2
            ;;
        esac

        mkdir -p "$state_dir"
        ln -sfn "$themes_dir/$id" "$state_dir/current"

        # Without a session bus (a TTY or SSH login) dconf cannot reach its
        # service; the next Home Manager activation reapplies the file.
        if [ -e "$state_dir/current/dconf.ini" ]; then
          dconf load / <"$state_dir/current/dconf.ini" 2>/dev/null ||
            echo "wl-theme: could not update the GTK settings (no session bus?)" >&2
        fi

        # GTK_THEME outranks both dconf and settings.ini and an installed name
        # that is not installed falls back to Adwaita light, which looks like
        # a broken theme selector. Every GTK app inherits it, so it has to be
        # cleared where the session is started, not here.
        if [ -n "''${GTK_THEME:-}" ]; then
          echo "wl-theme: GTK_THEME=$GTK_THEME overrides the active theme for GTK apps;" >&2
          echo "wl-theme: clear it from the session (logout, or 'systemctl --user unset-environment GTK_THEME')" >&2
        fi

        # Reload-free border update; the sourced file covers later reloads.
        if command -v hyprctl >/dev/null && hyprctl version >/dev/null 2>&1; then
          hyprctl --batch "keyword general:col.active_border rgb($active); keyword general:col.inactive_border rgb($inactive)" >/dev/null ||
            echo "wl-theme: could not update the Hyprland border colors" >&2
        fi

        # kitty rereads its config, and with it the theme include, on SIGUSR1.
        pkill -USR1 -x kitty || true

        if command -v tmux >/dev/null && tmux info >/dev/null 2>&1; then
          tmux run-shell ${lib.escapeShellArg "${config.xdg.configHome}/tmux/wl-theme.tmux"} ||
            echo "wl-theme: could not restyle tmux" >&2
        fi

        # herdr has no include, so `wl-theme set` repoints herdr/config.toml and
        # a running server reloads it for its clients. Best effort: no server
        # means the next launch reads the new file anyway.
        if command -v herdr >/dev/null && herdr status server >/dev/null 2>&1; then
          herdr server reload-config >/dev/null ||
            echo "wl-theme: could not reload the herdr config" >&2
        fi
        ;;

      *)
        usage
        exit 2
        ;;
    esac
  '';
}
