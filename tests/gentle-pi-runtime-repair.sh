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

# The other home: main installs gentle-pi as a git checkout, where the checkout
# is the package rather than a directory under node_modules.
checkout="$temporary_root/checkout"
checkout_marker="$temporary_root/checkout-postinstall.log"
mkdir -p "$checkout"
cat > "$checkout/package.json" <<'JSON'
{
  "name": "gentle-pi",
  "version": "2.4.0",
  "scripts": {
    "postinstall": "test -x /usr/bin/tar && printf '%s\\n' \"$GENTLE_PI_SKIP_GENTLE_AI_INSTALL\" >> \"$CHECKOUT_MARKER\" && test \"${FAIL_POSTINSTALL:-0}\" != 1"
  }
}
JSON
export CHECKOUT_MARKER="$checkout_marker"

"$repair" --package-dir "$checkout"

test "$(cat "$checkout_marker")" = "0"

if FAIL_POSTINSTALL=1 "$repair" --package-dir "$checkout"; then
  echo "repair accepted a failing gentle-pi postinstall from a git checkout" >&2
  exit 1
fi

# Activation runs both homes on every switch and only one of them holds
# gentle-pi, so the other one is nothing to repair rather than a failure. Both
# markers are read before and after, because tolerating a missing package by
# repairing something else would be the silent version of the same mistake.
missing_prefix="$temporary_root/missing-prefix"
missing_checkout="$temporary_root/missing-checkout"
prefix_before="$(cat "$marker")"
checkout_before="$(cat "$checkout_marker")"

"$repair" --prefix "$missing_prefix"
"$repair" --package-dir "$missing_checkout"

test "$(cat "$marker")" = "$prefix_before"
test "$(cat "$checkout_marker")" = "$checkout_before"

if "$repair" --invalid "$prefix"; then
  echo "repair accepted invalid arguments" >&2
  exit 1
fi
