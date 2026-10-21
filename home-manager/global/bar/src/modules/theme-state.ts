import app from "ags/gtk4/app";
import Gio from "gi://Gio";
import GLib from "gi://GLib";
import { createState } from "ags";
import { execAsync } from "ags/process";

import { DEFAULT_THEME, THEMES, THEME_CSS } from "../themes/index";

export type ThemeFamily = (typeof THEMES)[number]["family"];
export type ThemeMode = (typeof THEMES)[number]["mode"];

// The active theme is the target of the `wl-theme` state symlink (managed by
// the `wl-theme` script from home-manager/global/theme), so the bar, Hyprland,
// hyprlock and wofi share one persisted choice.
const STATE_DIR = `${GLib.get_user_state_dir()}/wl-theme`;
const CURRENT_LINK = `${STATE_DIR}/current`;

// `ln -sfn` replaces the link through a temporary name, so one switch is a
// burst of directory events.
const SYNC_DEBOUNCE_MS = 150;

function isThemeId(id: string): boolean {
  return THEMES.some((t) => t.id === id);
}

function readActiveTheme(): string {
  try {
    const target = GLib.file_read_link(CURRENT_LINK);
    const id = GLib.path_get_basename(target);

    return isThemeId(id) ? id : DEFAULT_THEME;
  } catch {
    return DEFAULT_THEME;
  }
}

function themeFor(family: ThemeFamily, mode: ThemeMode): string {
  return THEMES.find((t) => t.family === family && t.mode === mode)?.id ?? DEFAULT_THEME;
}

function familyOf(id: string): ThemeFamily {
  return THEMES.find((t) => t.id === id)?.family ?? "byzantium";
}

function modeOf(id: string): ThemeMode {
  return THEMES.find((t) => t.id === id)?.mode ?? "dark";
}

export function cssFor(id: string): string {
  return THEME_CSS[id] ?? THEME_CSS[DEFAULT_THEME];
}

export const [theme, setThemeState] = createState(readActiveTheme());
export const family = theme(familyOf);
export const mode = theme(modeOf);

function applyTheme(id: string): void {
  app.apply_css(cssFor(id), true);
  setThemeState(id);
}

// The latest theme picked in the bar that `wl-theme set` has not finished
// writing yet, and whether a write is running.
let pendingWrite: string | null = null;
let writing = false;

/**
 * Persists `pendingWrite` with one `wl-theme set` at a time. Concurrent runs
 * can finish out of order and leave the link on an older pick, so writes are
 * serialized and only the latest pick is written after the running one.
 */
function flushWrite(): void {
  if (writing || pendingWrite === null) return;

  const id = pendingWrite;
  writing = true;

  execAsync(["wl-theme", "set", id])
    .catch((err) => console.error(`wl-theme set ${id} failed: ${err}`))
    .finally(() => {
      writing = false;
      if (pendingWrite === id) pendingWrite = null;

      // Link changes made by another `wl-theme set` while this one ran were
      // ignored, so reconcile once the queue drains.
      if (pendingWrite === null) syncFromLink();
      else flushWrite();
    });
}

/**
 * Applies a theme to the bar immediately and persists it through `wl-theme`,
 * which also restyles the rest of the desktop. A failed persist keeps the bar
 * on the new theme for this session only.
 */
export function setTheme(id: string): void {
  if (!isThemeId(id) || id === theme.get()) return;

  applyTheme(id);

  pendingWrite = id;
  flushWrite();
}

let syncSource = 0;

/**
 * Follows the link when something else switches the theme (`wl-theme set` from
 * a terminal or keybind). While the bar's own writes are in flight the link
 * holds an older pick, so it is ignored until they settle.
 */
function syncFromLink(): void {
  if (syncSource !== 0) GLib.source_remove(syncSource);

  syncSource = GLib.timeout_add(GLib.PRIORITY_DEFAULT, SYNC_DEBOUNCE_MS, () => {
    syncSource = 0;

    if (!writing && pendingWrite === null) {
      const id = readActiveTheme();
      if (id !== theme.get()) applyTheme(id);
    }

    return GLib.SOURCE_REMOVE;
  });
}

function watchLink(): Gio.FileMonitor | null {
  try {
    GLib.mkdir_with_parents(STATE_DIR, 0o755);

    const monitor = Gio.File.new_for_path(STATE_DIR).monitor_directory(
      Gio.FileMonitorFlags.NONE,
      null,
    );
    monitor.connect("changed", syncFromLink);

    return monitor;
  } catch (err) {
    console.error(`cannot watch ${STATE_DIR}: ${err}`);
    return null;
  }
}

// Module-level so the monitor is not garbage collected.
const linkMonitor = watchLink();

export function setFamily(f: ThemeFamily): void {
  setTheme(themeFor(f, modeOf(theme.get())));
}

export function setMode(m: ThemeMode): void {
  setTheme(themeFor(familyOf(theme.get()), m));
}
