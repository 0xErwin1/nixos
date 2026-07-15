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

export const WIFI_ETHERNET = "\u{f0200}";
export const WIFI_WIFI = "\u{f1eb}";
export const WIFI_DISCONNECTED = "\u{f16b5}";

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
