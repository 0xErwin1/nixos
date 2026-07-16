import app from "ags/gtk4/app";
import GLib from "gi://GLib";
import { Astal, Gdk, Gtk } from "ags/gtk4";
import { createState, With } from "ags";
import { execAsync } from "ags/process";

import { AI_GLYPH, REFRESH_GLYPH, CLOSE_GLYPH } from "../glyphs";
import { extrasVisible, toggleExtras, closeExtras } from "./dashboard-state";
import { measureIslandX } from "./panel-position";

interface UsageWindow {
  label: string;
  usedPercent: number;
  resetAt: string | null;
}

interface UsageNote {
  label: string;
  value: string;
}

interface UsageProvider {
  id: string;
  name: string;
  plan: string | null;
  available: boolean;
  reason: string | null;
  windows: UsageWindow[];
  notes: UsageNote[] | null;
}

interface UsageData {
  generatedAt: string;
  providers: UsageProvider[];
}

const CACHE_SECONDS = 30;
const BACKGROUND_SECONDS = 120;

const [usage, setUsage] = createState<UsageData | null>(null);
const [loading, setLoading] = createState(false);
const [extrasX, setExtrasX] = createState(8);
let lastFetch = 0;

// The bar shells out to the packaged Go helper, which reads the local Claude /
// Codex OAuth credentials and returns a normalized usage document. Refreshed in
// the background so opening the panel shows fresh data instantly instead of
// waiting on a fetch; the short cache coalesces bursts.
function fetchUsage(force: boolean): void {
  if (loading.get()) return;

  const now = GLib.get_monotonic_time() / 1_000_000;
  if (!force && usage.get() !== null && now - lastFetch < CACHE_SECONDS) return;

  setLoading(true);
  execAsync(["epsilon-ai-usage"])
    .then((out) => {
      try {
        setUsage(JSON.parse(out) as UsageData);
        lastFetch = now;
      } catch {
        // Malformed output: keep the last good snapshot.
      }
    })
    .catch(() => {})
    .finally(() => setLoading(false));
}

// Warm the cache at startup and keep it fresh on a slow timer, so the panel is
// instant to open and does not hammer the provider APIs.
fetchUsage(true);
GLib.timeout_add_seconds(GLib.PRIORITY_DEFAULT, BACKGROUND_SECONDS, () => {
  fetchUsage(true);
  return GLib.SOURCE_CONTINUE;
});

export function openExtrasFrom(widget: Gtk.Widget | null): void {
  if (widget) setExtrasX(measureIslandX(widget));
  toggleExtras();
}

function reasonLabel(reason: string | null): string {
  switch (reason) {
    case "no-credentials":
      return "Not signed in";
    case "auth":
      return "Session expired — re-auth with the CLI";
    case "network":
      return "Offline";
    default:
      return reason ? `Unavailable (${reason})` : "Unavailable";
  }
}

function severity(percent: number): string {
  if (percent >= 90) return "ai-bar-crit";
  if (percent >= 70) return "ai-bar-warn";
  return "ai-bar-ok";
}

function resetLabel(iso: string | null): string {
  if (!iso) return "";

  const dt = GLib.DateTime.new_from_iso8601(iso, null);
  if (!dt) return "";

  const seconds = dt.difference(GLib.DateTime.new_now_local()) / 1_000_000;
  if (seconds <= 0) return "resetting…";

  if (seconds < 86400) {
    const hours = Math.floor(seconds / 3600);
    const minutes = Math.floor((seconds % 3600) / 60);
    return hours > 0 ? `resets in ${hours}h ${minutes}m` : `resets in ${minutes}m`;
  }

  return `resets ${dt.to_local().format("%b %d, %H:%M") ?? ""}`;
}

function WindowRow({ w }: { w: UsageWindow }) {
  return (
    <box cssClasses={["ai-window"]} orientation={Gtk.Orientation.VERTICAL} spacing={3}>
      <box valign={Gtk.Align.CENTER}>
        <label cssClasses={["ai-window-label"]} label={w.label} halign={Gtk.Align.START} hexpand />
        <label cssClasses={["ai-window-pct"]} label={`${w.usedPercent}%`} halign={Gtk.Align.END} />
      </box>
      <Gtk.ProgressBar
        cssClasses={["ai-bar", severity(w.usedPercent)]}
        fraction={Math.min(Math.max(w.usedPercent / 100, 0), 1)}
        showText={false}
        valign={Gtk.Align.CENTER}
      />
      <label
        cssClasses={["ai-window-reset"]}
        label={resetLabel(w.resetAt)}
        halign={Gtk.Align.START}
      />
    </box>
  );
}

function ProviderCard({ p }: { p: UsageProvider }) {
  return (
    <box cssClasses={["cc-box", "ai-card"]} orientation={Gtk.Orientation.VERTICAL} spacing={8}>
      <box valign={Gtk.Align.CENTER}>
        <label cssClasses={["ai-name"]} label={p.name} halign={Gtk.Align.START} hexpand />
        {p.plan ? <label cssClasses={["ai-plan"]} label={p.plan} /> : <box />}
      </box>

      {p.available ? (
        <box orientation={Gtk.Orientation.VERTICAL} spacing={10}>
          {p.windows.map((w) => (
            <WindowRow w={w} />
          ))}
          {p.notes && p.notes.length > 0 ? (
            <box cssClasses={["ai-notes"]} orientation={Gtk.Orientation.VERTICAL} spacing={2}>
              {p.notes.map((n) => (
                <box cssClasses={["ai-note"]} valign={Gtk.Align.CENTER}>
                  <label
                    cssClasses={["ai-note-label"]}
                    label={n.label}
                    halign={Gtk.Align.START}
                    hexpand
                  />
                  <label cssClasses={["ai-note-value"]} label={n.value} halign={Gtk.Align.END} />
                </box>
              ))}
            </box>
          ) : (
            <box />
          )}
        </box>
      ) : (
        <label
          cssClasses={["ai-unavailable"]}
          label={reasonLabel(p.reason)}
          halign={Gtk.Align.START}
        />
      )}
    </box>
  );
}

export function ExtrasPanel() {
  // Background refresh keeps the data fresh, so opening only needs to fetch if
  // nothing has loaded yet — that is what makes the panel instant to open.
  extrasVisible.subscribe(() => {
    if (extrasVisible.get() && usage.get() === null) fetchUsage(true);
  });

  const { TOP, BOTTOM, LEFT, RIGHT } = Astal.WindowAnchor;

  return (
    <window
      name="extras-panel"
      namespace="epsilon-extras"
      visible={extrasVisible}
      cssClasses={["extras-window"]}
      anchor={TOP | BOTTOM | LEFT | RIGHT}
      exclusivity={Astal.Exclusivity.IGNORE}
      layer={Astal.Layer.TOP}
      keymode={Astal.Keymode.ON_DEMAND}
      application={app}
    >
      <Gtk.EventControllerKey
        onKeyPressed={(_c, keyval: number) => {
          if (keyval === Gdk.KEY_Escape) closeExtras();
        }}
      />
      <overlay>
        <button cssClasses={["extras-backdrop"]} onClicked={closeExtras} />
        <box
          $type="overlay"
          cssClasses={["extras-card"]}
          orientation={Gtk.Orientation.VERTICAL}
          halign={Gtk.Align.START}
          valign={Gtk.Align.START}
          marginTop={42}
          marginStart={extrasX}
          spacing={12}
        >
          <box cssClasses={["ai-header"]} valign={Gtk.Align.CENTER} spacing={8}>
            <label cssClasses={["ai-title-glyph"]} label={AI_GLYPH} />
            <label cssClasses={["ai-title"]} label="AI Usage" halign={Gtk.Align.START} hexpand />
            <button cssClasses={["ai-icon-btn"]} onClicked={() => fetchUsage(true)}>
              <label label={REFRESH_GLYPH} />
            </button>
            <button cssClasses={["ai-icon-btn"]} onClicked={closeExtras}>
              <label label={CLOSE_GLYPH} />
            </button>
          </box>

          <Gtk.Spinner
            $={(self: Gtk.Spinner) => self.start()}
            visible={loading}
            halign={Gtk.Align.CENTER}
          />

          <With value={usage}>
            {(u: UsageData | null) =>
              u ? (
                <box orientation={Gtk.Orientation.VERTICAL} spacing={10}>
                  {u.providers.map((p) => (
                    <ProviderCard p={p} />
                  ))}
                </box>
              ) : (
                <label
                  cssClasses={["ai-empty"]}
                  label="No usage data"
                  visible={loading((l) => !l)}
                />
              )
            }
          </With>
        </box>
      </overlay>
    </window>
  );
}
