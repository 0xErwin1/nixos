# `wl-theme`: switches the active desktop theme at runtime.
#
# The active theme is one symlink, `<stateHome>/wl-theme/current`, pointing at
# `<configHome>/wl-theme/themes/<id>`. Hyprland and hyprlock `source` files
# through it and wofi's style.css resolves through it, so they pick up a change
# on their next (re)load; Hyprland's borders, kitty and tmux are also updated in
# place. The paths are baked in at build time so the script and the Hyprland
# `source` line can never disagree about where the link lives.
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
        ;;

      *)
        usage
        exit 2
        ;;
    esac
  '';
}
