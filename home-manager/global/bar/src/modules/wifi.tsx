import AstalNetwork from "gi://AstalNetwork";
import Pango from "gi://Pango";
import { Gtk } from "ags/gtk4";
import { createBinding, createComputed, createState, For, onCleanup } from "ags";
import { execAsync, subprocess } from "ags/process";

import {
  WIFI_ETHERNET,
  WIFI_WIFI,
  WIFI_DISCONNECTED,
  WIFI_LOCK,
  WIFI_ACTIVE,
  WIFI_REFRESH,
  wifiSignalGlyph,
} from "../glyphs";
import { openDashboard } from "./dashboard-state";

const network = AstalNetwork.get_default();

const WIFI_OFF_GLYPH = "\u{f092f}"; // wifi-strength-off-outline

// Connect/disconnect go through nmcli rather than AstalNetwork's native
// activate(): nmcli creates and persists the NetworkManager connection profile,
// handles the disconnect-first / wrong-password cases, and is the battle-tested
// path. AstalNetwork is used for the reactive state (enabled, scanning, access
// points, active AP). nmcli is a system binary always on the session PATH.
function connectKnownOrOpen(ssid: string): Promise<void> {
  // Array form (no shell) avoids SSID injection. Bring up a saved profile if
  // there is one, otherwise connect fresh (works for open networks).
  return execAsync(["nmcli", "connection", "up", "id", ssid])
    .then(() => undefined)
    .catch(() =>
      execAsync(["nmcli", "device", "wifi", "connect", ssid]).then(
        () => undefined,
      ),
    );
}

// Feed the password on stdin via `nmcli --ask` so it never appears in any
// process argv. Resolves on exit code 0, rejects otherwise (e.g. bad password).
function connectSecured(ssid: string, password: string): Promise<void> {
  return new Promise((resolve, reject) => {
    const proc = subprocess(
      ["nmcli", "--ask", "device", "wifi", "connect", ssid],
      () => {},
      () => {},
    );

    proc.connect("exit", (_p, code: number) => {
      if (code === 0) resolve();
      else reject(new Error("connect failed"));
    });

    proc.writeAsync(`${password}\n`).catch(() => {});
  });
}

function dedupeSort(
  aps: AstalNetwork.AccessPoint[],
): AstalNetwork.AccessPoint[] {
  const best = new Map<string, AstalNetwork.AccessPoint>();

  for (const ap of aps) {
    if (!ap.ssid) continue;
    const prev = best.get(ap.ssid);
    if (!prev || ap.strength > prev.strength) best.set(ap.ssid, ap);
  }

  return Array.from(best.values()).sort((a, b) => b.strength - a.strength);
}

function NetworkRow({
  ap,
  activeSsid,
  onActivate,
}: {
  ap: AstalNetwork.AccessPoint;
  activeSsid: ReturnType<typeof createBinding>;
  onActivate: (ap: AstalNetwork.AccessPoint) => void;
}) {
  const secured = ap.requiresPassword;

  return (
    <button cssClasses={["list-row", "wifi-row"]} onClicked={() => onActivate(ap)}>
      <box spacing={10}>
        <label cssClasses={["wifi-signal"]} label={wifiSignalGlyph(ap.strength)} />
        <label
          cssClasses={["wifi-ssid"]}
          label={ap.ssid}
          hexpand
          xalign={0}
          maxWidthChars={24}
          ellipsize={Pango.EllipsizeMode.END}
        />
        <label cssClasses={["wifi-lock"]} label={secured ? WIFI_LOCK : ""} />
        <label
          cssClasses={["wifi-check"]}
          label={activeSsid((s) => (s === ap.ssid ? WIFI_ACTIVE : ""))}
        />
      </box>
    </button>
  );
}

function WifiTabInner({ wifi }: { wifi: AstalNetwork.Wifi }) {
  const [selectedSsid, setSelectedSsid] = createState<string | null>(null);
  const [status, setStatus] = createState("");
  let passwordEntry: Gtk.Entry | null = null;

  const enabled = createBinding(wifi, "enabled");
  const scanning = createBinding(wifi, "scanning");
  const activeSsid = createBinding(wifi, "ssid");
  const activeAp = createBinding(wifi, "activeAccessPoint");
  const accessPoints = createBinding(wifi, "accessPoints")(dedupeSort);

  const emptyText = createComputed(
    [enabled, scanning, accessPoints],
    (en, sc, aps) =>
      !en
        ? "Wi-Fi is off"
        : aps.length > 0
          ? ""
          : sc
            ? "Scanning…"
            : "No networks found",
  );

  // Auto-scan when Wi-Fi is switched on (false -> true edge), so enabling the
  // radio immediately populates the list ("Scanning…") instead of needing a
  // manual Scan click. The manual Scan button still works.
  let prevEnabled = wifi.enabled;
  const unsubscribeEnabled = enabled.subscribe(() => {
    const nowEnabled = enabled.get();
    if (nowEnabled && !prevEnabled) wifi.scan();
    prevEnabled = nowEnabled;
  });
  onCleanup(unsubscribeEnabled);

  const disconnect = () => {
    setStatus("Disconnecting…");
    wifi.deactivate_connection((_p, res) => {
      try {
        wifi.deactivate_connection_finish(res);
      } catch {
        // already disconnected / nothing to do
      }
      setStatus("");
    });
  };

  const onActivate = (ap: AstalNetwork.AccessPoint) => {
    const active = wifi.activeAccessPoint;
    if (active && ap.ssid === active.ssid) {
      disconnect();
      return;
    }

    const saved = ap.get_connections().length > 0;
    if (ap.requiresPassword && !saved) {
      setSelectedSsid(ap.ssid);
      setStatus("");
      return;
    }

    setStatus(`Connecting to ${ap.ssid}…`);
    connectKnownOrOpen(ap.ssid)
      .then(() => setStatus(""))
      .catch(() => setStatus("Connection failed"));
  };

  const submitPassword = () => {
    const ssid = selectedSsid.get();
    if (!ssid || !passwordEntry) return;

    const password = passwordEntry.get_text();
    if (!password) {
      setStatus("Enter a password");
      return;
    }

    setStatus(`Connecting to ${ssid}…`);
    connectSecured(ssid, password)
      .then(() => {
        setSelectedSsid(null);
        setStatus("");
        passwordEntry?.set_text("");
      })
      .catch(() => setStatus("Check password"));
  };

  const focusGlyph = createComputed([enabled, activeAp], (en, ap) =>
    !en ? WIFI_OFF_GLYPH : ap ? wifiSignalGlyph(ap.strength) : WIFI_DISCONNECTED,
  );
  const focusTitle = createComputed([enabled, activeSsid], (en, s) =>
    !en ? "Wi-Fi Off" : s || "Not connected",
  );

  return (
    <box
      cssClasses={["tab", "wifi-tab"]}
      orientation={Gtk.Orientation.VERTICAL}
      hexpand
      vexpand
      spacing={12}
    >
      <box
        cssClasses={["focus-card"]}
        orientation={Gtk.Orientation.VERTICAL}
        hexpand
        halign={Gtk.Align.FILL}
      >
        <label cssClasses={["focus-glyph", "wifi-focus-glyph"]} label={focusGlyph} />
        <label cssClasses={["focus-title"]} label={focusTitle} />
        <label
          cssClasses={["focus-subtitle"]}
          label="Connected"
          visible={activeSsid((s) => !!s)}
        />
      </box>

      <box cssClasses={["actions-row"]} halign={Gtk.Align.CENTER} spacing={14}>
        <box cssClasses={["action-toggle"]} spacing={8}>
          <label label="Wi-Fi" />
          <switch
            active={enabled}
            valign={Gtk.Align.CENTER}
            onNotifyActive={(self) => {
              if (self.active !== wifi.enabled) wifi.set_enabled(self.active);
            }}
          />
        </box>
        <button
          cssClasses={["dash-btn"]}
          sensitive={enabled}
          onClicked={() => wifi.scan()}
        >
          <box spacing={6}>
            <label label={WIFI_REFRESH} />
            <label label="Scan" />
          </box>
        </button>
        <label
          cssClasses={["scan-indicator"]}
          label={scanning((s) => (s ? "Scanning…" : ""))}
        />
      </box>

      <box cssClasses={["wifi-active-row"]} visible={activeSsid((s) => !!s)}>
        <label
          cssClasses={["wifi-active-ssid"]}
          hexpand
          xalign={0}
          ellipsize={Pango.EllipsizeMode.END}
          label={activeSsid((s) => (s ? `Connected: ${s}` : ""))}
        />
        <button
          cssClasses={["dash-btn", "danger"]}
          label="Disconnect"
          onClicked={disconnect}
        />
      </box>

      <box cssClasses={["list-area"]} orientation={Gtk.Orientation.VERTICAL} vexpand>
        <box
          vexpand
          halign={Gtk.Align.CENTER}
          valign={Gtk.Align.CENTER}
          visible={emptyText((t) => !!t)}
        >
          <label cssClasses={["empty-label", "list-empty"]} label={emptyText} />
        </box>
        <scrolledwindow
          cssClasses={["list-scroll"]}
          vexpand
          hscrollbarPolicy={Gtk.PolicyType.NEVER}
          vscrollbarPolicy={Gtk.PolicyType.AUTOMATIC}
          visible={emptyText((t) => !t)}
        >
          <box cssClasses={["wifi-list"]} orientation={Gtk.Orientation.VERTICAL}>
            <For each={accessPoints}>
              {(ap) => (
                <NetworkRow ap={ap} activeSsid={activeSsid} onActivate={onActivate} />
              )}
            </For>
          </box>
        </scrolledwindow>
      </box>

      <revealer
        transitionType={Gtk.RevealerTransitionType.SLIDE_DOWN}
        transitionDuration={200}
        revealChild={selectedSsid((s) => s !== null)}
      >
        <box cssClasses={["wifi-password"]} orientation={Gtk.Orientation.VERTICAL} spacing={6}>
          <label
            xalign={0}
            label={selectedSsid((s) => (s ? `Password for ${s}` : ""))}
          />
          <box spacing={6}>
            <entry
              $={(self) => (passwordEntry = self)}
              hexpand
              visibility={false}
              placeholderText="Password"
              onActivate={submitPassword}
            />
            <button
              cssClasses={["dash-btn", "accent"]}
              label="Connect"
              onClicked={submitPassword}
            />
          </box>
        </box>
      </revealer>

      <label
        cssClasses={["statusline"]}
        xalign={0}
        visible={status((s) => !!s)}
        label={status}
      />
    </box>
  );
}

export function WifiTab() {
  const wifi = network.wifi;

  if (!wifi) {
    return (
      <box cssClasses={["tab", "wifi-tab"]}>
        <label label="No Wi-Fi device" />
      </box>
    );
  }

  return <WifiTabInner wifi={wifi} />;
}

export function WifiTrigger() {
  const state = createBinding(network, "state");

  const glyph = state(() => {
    if (network.primary === AstalNetwork.Primary.WIRED) return WIFI_ETHERNET;
    if (network.primary === AstalNetwork.Primary.WIFI || network.wifi)
      return WIFI_WIFI;
    return WIFI_DISCONNECTED;
  });

  const tooltip = state(() => {
    if (network.primary === AstalNetwork.Primary.WIRED) return "Wired";
    const ssid = network.wifi?.ssid;
    return ssid ? `Connected to ${ssid}` : "Disconnected";
  });

  return (
    <button
      cssClasses={["control-item", "wifi", "dash-trigger"]}
      tooltipText={tooltip}
      valign={Gtk.Align.CENTER}
      onClicked={() => openDashboard("wifi")}
    >
      <label
        cssClasses={["control-icon", "wifi-icon"]}
        label={glyph}
        valign={Gtk.Align.CENTER}
      />
    </button>
  );
}
