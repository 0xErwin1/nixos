// Nerd Font glyphs and icon-selection logic (icons + thresholds) for the bar.
// Codepoints are written as `\u{...}` escapes to keep the private-use glyphs
// unambiguous in source.

export const OS_NIXOS = "\u{f1105}";

export const WORKSPACE_GLYPHS: Record<number, string> = {
  1: "\u{f269}",
  2: "\u{e61d}",
  3: "\u{f120}",
  4: "\u{f268}",
  5: "\u{e615}",
  6: "\u{f07b}",
  7: "\u{f1c0}",
  8: "\u{f2c6}",
  9: "\u{f1bc}",
  10: "\u{f198}",
};

export const WINDOW_ICON = "\u{f2d0}";
export const FULLSCREEN_ICON = "\u{f0294}";

export const MIC_MUTED = "\u{f036d}";
export const MIC_UNMUTED = "\u{f036c}";

// Network status glyphs. Names are the Nerd Font glyph names as shipped in
// JetBrainsMono Nerd Font, not the upstream Material Design Icons names.
export const ETHERNET = "\u{f0200}"; // md-ethernet
export const WIFI = "\u{f1eb}"; // fa-wifi — generic, for the panel tab button
export const WIFI_OFF = "\u{f05aa}"; // md-wifi_off — radio disabled
export const WIFI_UNAVAILABLE = "\u{f092e}"; // md-wifi_strength_off_outline
export const WIFI_SYNC = "\u{f16c7}"; // md-wifi_sync — associating
export const WIFI_PORTAL = "\u{f16bf}"; // md-wifi_lock — captive portal
export const VPN = "\u{f0582}"; // md-vpn — panel row, where the linework reads
// Badge-scale tunnel marker. md-vpn's strokes turn to mush overlaid on another
// glyph, so the bar uses a solid silhouette that survives the downscale.
export const VPN_BADGE = "\u{f0565}"; // md-shield_check

// Reachability glyphs for wired: the font has no ethernet variants, so the
// degraded wired states borrow the "web" family, which names the thing that is
// actually degraded (internet reachability) rather than the medium.
export const INTERNET_OFF = "\u{f0a8e}"; // md-web_off
export const INTERNET_SYNC = "\u{f1792}"; // md-web_sync
export const INTERNET_PORTAL = "\u{f1791}"; // md-web_refresh

// Wi-Fi dashboard panel glyphs.
export const WIFI_LOCK = "\u{f033e}"; // md-lock
export const WIFI_ACTIVE = "\u{f012c}"; // md-check
export const WIFI_REFRESH = "\u{f0450}"; // md-refresh

export function wifiSignalGlyph(strength: number): string {
  if (strength >= 75) return "\u{f0928}"; // md-wifi_strength_4
  if (strength >= 50) return "\u{f0925}"; // md-wifi_strength_3
  if (strength >= 25) return "\u{f0922}"; // md-wifi_strength_2
  if (strength > 0) return "\u{f091f}"; // md-wifi_strength_1
  return "\u{f092f}"; // md-wifi_strength_outline
}

/** Same signal buckets, but marked as associated without internet access. */
export function wifiSignalAlertGlyph(strength: number): string {
  if (strength >= 75) return "\u{f0929}"; // md-wifi_strength_4_alert
  if (strength >= 50) return "\u{f0926}"; // md-wifi_strength_3_alert
  if (strength >= 25) return "\u{f0923}"; // md-wifi_strength_2_alert
  if (strength > 0) return "\u{f0920}"; // md-wifi_strength_1_alert
  return "\u{f092b}"; // md-wifi_strength_alert_outline
}

// Bluetooth + dashboard glyphs.
export const BT_ON = "\u{f00af}"; // bluetooth
export const BT_CONNECTED = "\u{f00b1}"; // bluetooth-connect
export const BT_OFF = "\u{f00b2}"; // bluetooth-off
export const CLOSE_GLYPH = "\u{f0156}"; // close
export const TRUST_GLYPH = "\u{f012c}"; // check
export const FORGET_GLYPH = "\u{f0a7a}"; // delete-outline

export function btStateGlyph(powered: boolean, connected: boolean): string {
  if (!powered) return BT_OFF;
  if (connected) return BT_CONNECTED;
  return BT_ON;
}

// Notification bell glyphs.
export const BELL = "\u{f009a}"; // bell
export const BELL_ACTIVE = "\u{f009c}"; // bell-ring
export const BELL_DND = "\u{f009b}"; // bell-off

// Control-center power glyphs.
export const LOCK_GLYPH = "\u{f033e}"; // lock
export const SUSPEND_GLYPH = "\u{f0904}"; // power-sleep
export const LOGOUT_GLYPH = "\u{f0343}"; // logout
export const RESTART_GLYPH = "\u{f0454}"; // restart
export const SHUTDOWN_GLYPH = "\u{f0425}"; // power

export function batteryGlyph(percent: number, charging: boolean): string {
  if (charging) return "\u{e00a}";
  if (percent >= 90) return "\u{f240}";
  if (percent >= 70) return "\u{f241}";
  if (percent >= 30) return "\u{f242}";
  return "\u{f243}";
}

// All-MDI volume glyphs (F05xx): unlike the Font Awesome speaker glyphs
// (U+F028/U+F027), their ink stays within the advance width, so the icon does
// not overlap the adjacent percentage label.
export function volumeGlyph(percent: number, muted: boolean): string {
  if (muted || percent <= 0) return "\u{f0581}"; // volume-off
  if (percent >= 70) return "\u{f057e}"; // volume-high
  if (percent >= 40) return "\u{f0580}"; // volume-medium
  return "\u{f057f}"; // volume-low
}

export function brightnessGlyph(percent: number): string {
  if (percent >= 70) return "\u{f00e0}";
  if (percent >= 40) return "\u{f00df}";
  if (percent >= 10) return "\u{f00dd}";
  if (percent >= 1) return "\u{f00de}";
  return "\u{f00e1}";
}

// Weather (WMO weather codes → MDI weather glyphs). Day/night variants are
// chosen for clear/partly-cloudy since those read very differently at night.
export const WIND_GLYPH = "\u{f059d}"; // weather-windy
export const HUMIDITY_GLYPH = "\u{f058e}"; // water-percent
export const RAIN_GLYPH = "\u{f0597}"; // weather-rainy
export const FEELS_GLYPH = "\u{f050f}"; // thermometer

const WMO_PARTLY_CLOUDY = new Set([1, 2]);
const WMO_FOG = new Set([45, 48]);
const WMO_RAINY = new Set([51, 53, 55, 56, 57, 61, 63, 80, 81]);
const WMO_POURING = new Set([65, 66, 67, 82]);
const WMO_SNOW = new Set([71, 73, 75, 77, 85, 86]);
const WMO_THUNDER = new Set([95, 96, 99]);

export function weatherGlyph(code: number, isNight: boolean): string {
  if (WMO_THUNDER.has(code)) return "\u{f067e}"; // weather-lightning-rainy
  if (WMO_SNOW.has(code)) return "\u{f0598}"; // weather-snowy
  if (WMO_POURING.has(code)) return "\u{f0596}"; // weather-pouring
  if (WMO_RAINY.has(code)) return "\u{f0597}"; // weather-rainy
  if (WMO_FOG.has(code)) return "\u{f0591}"; // weather-fog
  if (WMO_PARTLY_CLOUDY.has(code)) return isNight ? "\u{f0f31}" : "\u{f0595}";
  if (code === 3) return "\u{f0590}"; // weather-cloudy

  return isNight ? "\u{f0594}" : "\u{f0599}"; // clear: night / sunny
}

// Calendar navigation.
export const CHEVRON_LEFT = "\u{f0141}";
export const CHEVRON_RIGHT = "\u{f0142}";
export const CHEVRON_DOWN = "\u{f0140}";
export const CHEVRON_UP = "\u{f0143}";

// Extras panel (AI usage).
export const AI_GLYPH = "\u{f06a9}"; // robot
export const REFRESH_GLYPH = "\u{f0450}"; // refresh

// Media (MPRIS) player controls.
export const MEDIA_MUSIC = "\u{f075a}"; // music
export const MEDIA_PLAY = "\u{f040a}"; // play
export const MEDIA_PAUSE = "\u{f03e4}"; // pause
export const MEDIA_PREV = "\u{f04ae}"; // skip-previous
export const MEDIA_NEXT = "\u{f04ad}"; // skip-next
