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

interface UsageDayCost {
  date: string;
  tokens: number;
  estUsd: number;
}

interface UsageModelCost {
  model: string;
  tokens: number;
  estUsd: number;
}

interface UsageCost {
  today: UsageDayCost;
  week: UsageDayCost;
  days: UsageDayCost[];
  models: UsageModelCost[] | null;
}

interface UsageProvider {
  id: string;
  name: string;
  plan: string | null;
  available: boolean;
  reason: string | null;
  windows: UsageWindow[];
  notes: UsageNote[] | null;
  cost: UsageCost | null;
}

interface UsageData {
  generatedAt: string;
  providers: UsageProvider[];
}

const CACHE_SECONDS = 30;
// Background poll cadence. Also the worst-case latency for the usage
// threshold/reset alerts, so kept fairly tight; the provider APIs tolerate a
// once-a-minute check.
const BACKGROUND_SECONDS = 60;

const [usage, setUsage] = createState<UsageData | null>(null);
const [loading, setLoading] = createState(false);
const [extrasX, setExtrasX] = createState(8);
let lastFetch = 0;

// ── Usage threshold + reset notifications ──────────────────────────────────────
// Per-window snapshot from the previous poll, keyed by provider + window label,
// so crossings and resets can be detected between fetches. In-memory only: after
// a bar restart the first poll re-seeds baselines without firing, so an already
// high level does not trigger a retroactive alert.
interface WindowState {
  percent: number;
  resetAt: string | null;
}

const usageState = new Map<string, WindowState>();
const USAGE_THRESHOLDS = [100, 50];
const RESET_DROP_POINTS = 15;
const RESET_FORWARD_SECONDS = 1800;

function notifyUsage(
  urgency: "low" | "normal" | "critical",
  summary: string,
  body: string,
): void {
  // Routed through notify-send to our own notifd, so it shows as a popup and
  // lands in the notification center like any other notification.
  execAsync(["notify-send", "-a", "AI Usage", "-u", urgency, summary, body]).catch(
    () => {},
  );
}

function isoToUnix(iso: string | null): number | null {
  if (!iso) return null;
  const dt = GLib.DateTime.new_from_iso8601(iso, null);
  return dt ? dt.to_unix() : null;
}

function checkWindowEvents(providerName: string, w: UsageWindow): void {
  const key = `${providerName}:${w.label}`;
  const prev = usageState.get(key);
  const cur: WindowState = { percent: w.usedPercent, resetAt: w.resetAt };

  if (!prev) {
    usageState.set(key, cur);
    return;
  }

  // A reset drops usage and never coincides with an upward crossing, so the two
  // checks are mutually exclusive within a single poll.
  const crossed = USAGE_THRESHOLDS.find(
    (t) => prev.percent < t && cur.percent >= t,
  );
  if (crossed === 100) {
    notifyUsage(
      "critical",
      `${providerName}: ${w.label} limit reached`,
      `100% used · ${resetLabel(w.resetAt)}`,
    );
  } else if (crossed === 50) {
    notifyUsage(
      "normal",
      `${providerName}: ${w.label} at 50%`,
      resetLabel(w.resetAt) || "Half of the window used",
    );
  }

  // Usage is monotonic within a window, so a clear drop means it rolled over.
  // Also catch a low-usage reset via the reset timestamp jumping forward, while
  // ignoring minor API jitter in that timestamp.
  const prevReset = isoToUnix(prev.resetAt);
  const curReset = isoToUnix(cur.resetAt);
  const droppedUsage = prev.percent - cur.percent >= RESET_DROP_POINTS;
  const jumpedForward =
    prevReset !== null &&
    curReset !== null &&
    curReset - prevReset >= RESET_FORWARD_SECONDS &&
    cur.percent <= prev.percent;

  if (droppedUsage || jumpedForward) {
    notifyUsage("normal", `${providerName}: ${w.label} reset`, "Fresh quota available");
  }

  usageState.set(key, cur);
}

function checkUsageEvents(data: UsageData): void {
  for (const p of data.providers) {
    if (!p.available) continue;
    for (const w of p.windows) checkWindowEvents(p.name, w);
  }
}

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
        const parsed = JSON.parse(out) as UsageData;
        setUsage(parsed);
        lastFetch = now;
        checkUsageEvents(parsed);
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

function fmtTokens(n: number): string {
  if (n >= 1e9) return `${(n / 1e9).toFixed(1)}B`;
  if (n >= 1e6) return `${Math.round(n / 1e6)}M`;
  if (n >= 1e3) return `${Math.round(n / 1e3)}k`;
  return `${n}`;
}

function fmtUsd(n: number): string {
  return n >= 100 ? `$${Math.round(n)}` : `$${n.toFixed(2)}`;
}

function fmtDay(iso: string, today: string): string {
  if (iso === today) return "Today";
  const dt = GLib.DateTime.new_from_iso8601(`${iso}T12:00:00Z`, null);
  return dt ? (dt.format("%a %d") ?? iso) : iso;
}

function CostRow({
  label,
  cost,
  total,
  today,
}: {
  label: string;
  cost: UsageDayCost;
  total: boolean;
  today: string;
}) {
  return (
    <box
      cssClasses={total ? ["ai-cost-row", "ai-cost-total"] : ["ai-cost-row"]}
      valign={Gtk.Align.CENTER}
    >
      <label
        cssClasses={["ai-cost-day", label === "Today" ? "today" : ""]}
        label={label}
        halign={Gtk.Align.START}
        hexpand
      />
      <label cssClasses={["ai-cost-tokens"]} label={fmtTokens(cost.tokens)} />
      <label cssClasses={["ai-cost-usd"]} label={`~${fmtUsd(cost.estUsd)}`} />
    </box>
  );
}

function ModelRow({ model }: { model: UsageModelCost }) {
  return (
    <box cssClasses={["ai-cost-row"]} valign={Gtk.Align.CENTER}>
      <label
        cssClasses={["ai-cost-day"]}
        label={model.model}
        halign={Gtk.Align.START}
        hexpand
      />
      <label cssClasses={["ai-cost-tokens"]} label={fmtTokens(model.tokens)} />
      <label cssClasses={["ai-cost-usd"]} label={`~${fmtUsd(model.estUsd)}`} />
    </box>
  );
}

function CostSection({ cost }: { cost: UsageCost }) {
  const models = cost.models ?? [];

  return (
    <box cssClasses={["ai-cost"]} orientation={Gtk.Orientation.VERTICAL} spacing={3}>
      <label
        cssClasses={["ai-cost-title"]}
        label="Usage · est. API cost"
        halign={Gtk.Align.START}
      />
      {cost.days.map((d) => (
        <CostRow label={fmtDay(d.date, cost.today.date)} cost={d} total={false} today={cost.today.date} />
      ))}
      <CostRow label="7-day total" cost={cost.week} total today={cost.today.date} />

      {models.length > 0 && (
        <box orientation={Gtk.Orientation.VERTICAL} spacing={3}>
          <label
            cssClasses={["ai-cost-title", "ai-cost-subtitle"]}
            label="By model · 7 days"
            halign={Gtk.Align.START}
          />
          {models.map((m) => (
            <ModelRow model={m} />
          ))}
        </box>
      )}
    </box>
  );
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
          {p.cost ? <CostSection cost={p.cost} /> : <box />}
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
      namespace="wl-extras"
      visible={extrasVisible}
      cssClasses={["extras-window"]}
      anchor={TOP | BOTTOM | LEFT | RIGHT}
      exclusivity={Astal.Exclusivity.NORMAL}
      layer={Astal.Layer.TOP}
      keymode={Astal.Keymode.ON_DEMAND}
      onNotifyIsActive={(self) => {
        if (!self.get_property("is-active")) closeExtras();
      }}
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
          marginTop={8}
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
