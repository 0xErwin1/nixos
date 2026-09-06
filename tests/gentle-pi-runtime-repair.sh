#!/usr/bin/env bash
set -euo pipefail

repair="$1"
temporary_root="$(mktemp -d)"
cleanup() {
  rm -rf "$temporary_root"
}
trap cleanup EXIT

export HOME="$temporary_root/home"
export XDG_CONFIG_HOME="$HOME/config"
export npm_config_cache="$temporary_root/npm-cache"
export npm_config_offline=true
export npm_config_registry="http://127.0.0.1:9"
export NPM_CONFIG_UPDATE_NOTIFIER=false
mkdir -p "$HOME" "$npm_config_cache"

prefix="$temporary_root/prefix"
mkdir -p "$prefix/node_modules/gentle-pi" "$prefix/node_modules/unrelated"
marker="$temporary_root/postinstall.log"
unrelated_marker="$temporary_root/unrelated.log"

cat > "$prefix/node_modules/gentle-pi/package.json" <<'JSON'
{
  "name": "gentle-pi",
  "version": "2.4.0",
  "scripts": {
    "postinstall": "test -x /usr/bin/tar && printf '%s\\n' \"$GENTLE_PI_SKIP_GENTLE_AI_INSTALL\" >> \"$MARKER\" && test \"${FAIL_POSTINSTALL:-0}\" != 1"
  }
}
JSON
cat > "$prefix/node_modules/unrelated/package.json" <<'JSON'
{
  "name": "unrelated",
  "version": "1.0.0",
  "scripts": {
    "postinstall": "printf unrelated >> \"$UNRELATED_MARKER\""
  }
}
JSON

export MARKER="$marker"
export UNRELATED_MARKER="$unrelated_marker"
host_path="$PATH"
host_tar="$(command -v tar)"

"$repair" --prefix "$prefix"
"$repair" --prefix "$prefix"

test "$PATH" = "$host_path"
test "$(command -v tar)" = "$host_tar"
test "$(cat "$marker")" = $'0\n0'
test ! -e "$unrelated_marker"

if FAIL_POSTINSTALL=1 "$repair" --prefix "$prefix"; then
  echo "repair accepted a failing gentle-pi postinstall" >&2
  exit 1
fi

if "$repair" --invalid "$prefix"; then
  echo "repair accepted invalid arguments" >&2
  exit 1
fi

missing_prefix="$temporary_root/missing-prefix"
if "$repair" --prefix "$missing_prefix"; then
  echo "repair accepted a missing gentle-pi package" >&2
  exit 1
fi
