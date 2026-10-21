import AstalNetwork from "gi://AstalNetwork";
import Pango from "gi://Pango";
import { Gtk } from "ags/gtk4";
import { createBinding, createComputed, createState, For, onCleanup } from "ags";
import { execAsync, subprocess } from "ags/process";

import {
  WIFI_LOCK,
  WIFI_ACTIVE,
  WIFI_OFF,
  WIFI_REFRESH,
  wifiSignalGlyph,
} from "../glyphs";
import {
  networkStatus,
  networkGlyph,
  reachLabel,
  statusTooltip,
} from "./network-state";
import { tunnelBadgeGlyph } from "./tunnel-state";
import {
  openDashboard,
  closeDashboard,
  dashboardVisible,
  anyPanelOpen,
} from "./dashboard-state";

const network = AstalNetwork.get_default();

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
  onActivate,
}: {
  ap: AstalNetwork.AccessPoint;
  onActivate: (ap: AstalNetwork.AccessPoint) => void;
}) {
  const secured = ap.requiresPassword;

  return (
    <button cssClasses={["panel-row"]} onClicked={() => onActivate(ap)}>
      <box spacing={12}>
        <label cssClasses={["panel-row-icon"]} label={wifiSignalGlyph(ap.strength)} />
        <label
          cssClasses={["panel-row-title"]}
          label={ap.ssid}
          hexpand
          xalign={0}
          maxWidthChars={24}
          ellipsize={Pango.EllipsizeMode.END}
        />
        <label
          cssClasses={["panel-row-trail"]}
          label={WIFI_LOCK}
          visible={secured}
          tooltipText="Secured"
        />
      </box>
    </button>
  );
}

function WifiSectionInner({ wifi }: { wifi: AstalNetwork.Wifi }) {
  const [selectedSsid, setSelectedSsid] = createState<string | null>(null);
  const [status, setStatus] = createState("");
  let passwordEntry: Gtk.Entry | null = null;

  const enabled = createBinding(wifi, "enabled");
  const scanning = createBinding(wifi, "scanning");
  const activeSsid = createBinding(wifi, "ssid");
  const strength = createBinding(wifi, "strength");
  const accessPoints = createBinding(wifi, "accessPoints")(dedupeSort);

  // The connected network has its own row at the top, so the list below only
  // offers the networks the user can switch to.
  const otherNetworks = createComputed(
    [accessPoints, activeSsid],
    (aps, active) => aps.filter((ap) => ap.ssid !== active),
  );

  // While a scan runs the section header already says "Scanning…".
  const emptyText = createComputed(
    [scanning, otherNetworks, activeSsid],
    (sc, others, active) =>
      others.length === 0 && !active && !sc ? "No networks found" : "",
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

  // Same derived status as the bar trigger, so a degraded link reads the same
  // in the row as on the icon the user clicked to open the panel.
  const connectedSubtitle = networkStatus((s) =>
    s.medium === "wifi" && s.reach !== "online" ? reachLabel(s) : "Connected",
  );

  return (
    <box cssClasses={["panel-section"]} orientation={Gtk.Orientation.VERTICAL} spacing={6}>
      <box cssClasses={["panel-section-head"]} spacing={8}>
        <label cssClasses={["panel-section-label"]} label="WI-FI" hexpand xalign={0} />
        <label
          cssClasses={["panel-section-hint"]}
          label={scanning((s) => (s ? "Scanning…" : ""))}
        />
        <button
          cssClasses={["panel-icon-btn"]}
          tooltipText="Scan"
          visible={enabled}
          onClicked={() => wifi.scan()}
        >
          <label label={WIFI_REFRESH} />
        </button>
        <switch
          active={enabled}
          valign={Gtk.Align.CENTER}
          onNotifyActive={(self) => {
            if (self.active !== wifi.enabled) wifi.set_enabled(self.active);
          }}
        />
      </box>

      <box cssClasses={["panel-group"]} orientation={Gtk.Orientation.VERTICAL}>
        <box cssClasses={["panel-row", "muted"]} spacing={12} visible={enabled((e) => !e)}>
          <label cssClasses={["panel-row-icon"]} label={WIFI_OFF} />
          <label cssClasses={["panel-row-title"]} label="Wi-Fi is off" hexpand xalign={0} />
        </box>

        <box orientation={Gtk.Orientation.VERTICAL} visible={enabled}>
          <box
            cssClasses={["panel-row", "static"]}
            spacing={12}
            visible={activeSsid((s) => !!s)}
          >
            <label
              cssClasses={["panel-row-icon", "on"]}
              label={strength((s) => wifiSignalGlyph(s))}
            />
            <box orientation={Gtk.Orientation.VERTICAL} hexpand valign={Gtk.Align.CENTER}>
              <label
                cssClasses={["panel-row-title"]}
                label={activeSsid((s) => s ?? "")}
                xalign={0}
                maxWidthChars={20}
                ellipsize={Pango.EllipsizeMode.END}
              />
              <label cssClasses={["panel-row-subtitle"]} label={connectedSubtitle} xalign={0} />
            </box>
            <button
              cssClasses={["dash-btn", "danger", "panel-row-action"]}
              label="Disconnect"
              valign={Gtk.Align.CENTER}
              onClicked={disconnect}
            />
            <label cssClasses={["panel-row-check"]} label={WIFI_ACTIVE} />
          </box>

          <For each={otherNetworks}>
            {(ap) => <NetworkRow ap={ap} onActivate={onActivate} />}
          </For>

          <label
            cssClasses={["panel-empty"]}
            xalign={0}
            visible={emptyText((t) => !!t)}
            label={emptyText}
          />

          <revealer
            transitionType={Gtk.RevealerTransitionType.SLIDE_DOWN}
            transitionDuration={200}
            revealChild={selectedSsid((s) => s !== null)}
          >
            <box cssClasses={["net-password"]} orientation={Gtk.Orientation.VERTICAL} spacing={6}>
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
        </box>

        <label
          cssClasses={["statusline", "net-status"]}
          xalign={0}
          visible={status((s) => !!s)}
          label={status}
        />
      </box>
    </box>
  );
}

/** The Wi-Fi section of the Network panel: radio switch, connected network and scan list. */
export function WifiSection() {
  const wifi = network.wifi;

  if (!wifi) {
    return (
      <box cssClasses={["panel-section"]} orientation={Gtk.Orientation.VERTICAL} spacing={6}>
        <label cssClasses={["panel-section-label"]} label="WI-FI" xalign={0} />
        <box cssClasses={["panel-group"]}>
          <box cssClasses={["panel-row", "muted"]} spacing={12}>
            <label cssClasses={["panel-row-icon"]} label={WIFI_OFF} />
            <label cssClasses={["panel-row-title"]} label="No Wi-Fi device" xalign={0} />
          </box>
        </box>
      </box>
    );
  }

  return <WifiSectionInner wifi={wifi} />;
}

export function WifiTrigger() {
  const glyph = networkStatus(networkGlyph);
  const tooltip = networkStatus(statusTooltip);
  // The badge names the first tunnel's kind: with more than one up, the icon
  // can only carry "a tunnel is up" anyway, and the tooltip lists them all.
  const vpnBadge = networkStatus((status) =>
    status.vpn.length > 0 ? tunnelBadgeGlyph(status.vpn[0].kind) : "",
  );

  // One state class at a time so the stylesheet can colour the icon by
  // reachability (degraded states read as warnings) without any inline styling.
  const iconClasses = networkStatus((status) => [
    "control-icon",
    "wifi-icon",
    `net-${status.reach}`,
  ]);

  // Press-based (GestureClick) rather than a <button>'s release-based click: a
  // button spawned the focus-taking panel window and then needed a pointer
  // motion to re-arm before the next click closed it. openDashboard() closes any
  // other open panel (including the center) via the shared exclusion group.
  const activate = () => {
    if (dashboardVisible.get()) {
      closeDashboard();
    } else {
      openDashboard("wifi");
    }
  };

  return (
    <box
      cssClasses={["control-item", "wifi", "dash-trigger"]}
      tooltipText={tooltip}
      valign={Gtk.Align.CENTER}
    >
      <Gtk.GestureClick onPressed={activate} />
      <Gtk.EventControllerMotion
        onEnter={() => {
          if (anyPanelOpen()) openDashboard("wifi");
        }}
      />
      <overlay>
        <label cssClasses={iconClasses} label={glyph} valign={Gtk.Align.CENTER} />
        {/* Overlaid rather than placed beside the icon: the control row keeps a
            uniform slot per glyph, so a second child would make this the one
            trigger wider than the rest. Sits bottom-end, clear of the signal
            glyph's dense corner. */}
        <label
          $type="overlay"
          cssClasses={["wifi-vpn-badge"]}
          label={vpnBadge}
          halign={Gtk.Align.END}
          valign={Gtk.Align.END}
          visible={vpnBadge((badge) => !!badge)}
        />
      </overlay>
    </box>
  );
}
