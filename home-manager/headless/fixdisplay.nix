{ pkgs, ... }:
# SSH X11 tunnels die with their connection, but herdr/tmux panes outlive it,
# so DISPLAY inside a pane goes stale or empty. `fixdisplay` rediscovers the
# newest live tunnel: sshd listens on 127.0.0.1:6000+N for forwarded display N.
# Community workaround from https://github.com/herdrdev/herdr/discussions/474
# until herdr refreshes per-connection environment on attach.
{
  home.packages = [ pkgs.xauth ];

  programs.zsh.initContent = ''
    _x11_find_display() {
      local ports port n
      ports=$(ss -ltn 2>/dev/null | awk '
        $4 ~ /^127\.0\.0\.1:60[0-9][0-9]$/ {
          split($4, a, ":"); print a[2]
        }' | sort -n)
      [ -z "$ports" ] && return 1

      for port in $(echo "$ports" | tac); do
        n=$((port - 6000))
        if xauth list 2>/dev/null | grep -qE "[:/]''${n}( |$)"; then
          printf 'localhost:%s.0' "$n"
          return 0
        fi
      done

      port=$(echo "$ports" | tail -1)
      printf 'localhost:%s.0' "$((port - 6000))"
    }

    _x11_save_display() {
      local d="''${1:-$DISPLAY}"
      [ -n "$d" ] || return 1
      umask 077
      {
        printf 'export DISPLAY=%q\n' "$d"
        [ -n "''${XAUTHORITY:-}" ] && printf 'export XAUTHORITY=%q\n' "$XAUTHORITY"
      } > "$HOME/.xdisplay"
    }

    fixdisplay() {
      local d
      if [[ -n ''${TMUX:-} ]]; then
        if eval "$(tmux showenv -s DISPLAY 2>/dev/null)"; then
          _x11_save_display
          echo "DISPLAY=$DISPLAY (from tmux)"
          return 0
        fi
      fi
      d=$(_x11_find_display) || {
        echo "fixdisplay: no SSH X11 listener on 127.0.0.1:60xx" >&2
        return 1
      }
      export DISPLAY="$d"
      _x11_save_display "$d"
      echo "DISPLAY=$DISPLAY"
    }

    if [[ $- == *i* ]]; then
      if [[ -n ''${TMUX:-} ]]; then
        eval "$(tmux showenv -s DISPLAY 2>/dev/null)" || true
      fi
      if [[ "''${DISPLAY:-}" == localhost:* || "''${DISPLAY:-}" == 127.0.0.1:* ]]; then
        _x11_save_display
      else
        if _fixdisplay_found=$(_x11_find_display); then
          export DISPLAY="$_fixdisplay_found"
          _x11_save_display "$_fixdisplay_found"
        elif [[ -f "$HOME/.xdisplay" ]]; then
          source "$HOME/.xdisplay"
        fi
        unset _fixdisplay_found
      fi
    fi
  '';
}
