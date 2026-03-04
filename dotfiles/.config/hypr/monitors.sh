#!/usr/bin/env bash
set -euo pipefail

hyprctl -j monitors >/dev/null 2>&1 || exit 0

monitors_json="$(hyprctl -j monitors)"

has() { echo "$monitors_json" | grep -q "\"name\":\"$1\""; }

hyprctl keyword monitor ",preferred,auto,1" >/dev/null

if has "DP-1"; then
  hyprctl keyword monitor "eDP-1,1920x1080@60,0x0,1"
  hyprctl keyword monitor "DP-1,1920x1080@60,0x1080,1"
  exit 0
fi

if has "HDMI-A-1"; then
  hyprctl keyword monitor "eDP-1,1920x1080@60,0x0,1"
  hyprctl keyword monitor "HDMI-A-1,1920x1080@60,0x1080,1"
  exit 0
fi

hyprctl keyword monitor "eDP-1,1920x1080@60,0x0,1"
