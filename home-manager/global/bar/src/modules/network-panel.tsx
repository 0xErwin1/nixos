import Pango from "gi://Pango";
import { Gtk } from "ags/gtk4";
import { createComputed, For } from "ags";
import { execAsync } from "ags/process";

import { ETHERNET, WIFI_ACTIVE } from "../glyphs";
import { NetStatus, networkStatus, reachLabel } from "./network-state";
import {
  TunnelKind,
  meshLinkPresent,
  tunnelGlyph,
  tunnelKindLabel,
  tunnels,
} from "./tunnel-state";
import { closeDashboard } from "./dashboard-state";
import { WifiSection } from "./wifi";
import { BluetoothSection } from "./bluetooth";

// Panel-only glyphs. Local until they move to glyphs.ts.
const SETTINGS_GLYPH = "\u{f0493}"; // md-cog
const BT_SETTINGS_GLYPH = "\u{f00b3}"; // md-bluetooth_settings
const EXTERNAL_GLYPH = "\u{f03cc}"; // md-open_in_new

// Tallest the panel body grows before it scrolls, in logical pixels. Leaves
// room for the bar and the card chrome on an 800px-tall logical screen.
const MAX_BODY_HEIGHT = 600;

function formatSpeed(mbps: number): string {
  if (mbps < 1000) return `${mbps} Mb/s`;

  const gbps = mbps / 1000;
  return `${Number.isInteger(gbps) ? gbps : gbps.toFixed(1)} Gb/s`;
}

function ethernetSubtitle(status: NetStatus): string {
  const state = status.reach === "online" ? "Connected" : reachLabel(status);
  return status.wiredSpeed > 0 ? `${state} · ${formatSpeed(status.wiredSpeed)}` : state;
}

function EthernetRow() {
  const wired = networkStatus((s) => s.medium === "wired");

  return (
    <box cssClasses={["panel-group"]} visible={wired}>
      <box cssClasses={["panel-row", "static"]} spacing={12} hexpand>
        <label cssClasses={["panel-row-icon", "on"]} label={ETHERNET} />
        <box orientation={Gtk.Orientation.VERTICAL} hexpand valign={Gtk.Align.CENTER}>
          <label cssClasses={["panel-row-title"]} label="Ethernet" xalign={0} />
          <label
            cssClasses={["panel-row-subtitle"]}
            label={networkStatus(ethernetSubtitle)}
            xalign={0}
          />
        </box>
        <label
          cssClasses={["panel-row-check"]}
          label={WIFI_ACTIVE}
          visible={networkStatus((s) => s.reach !== "connecting")}
        />
      </box>
    </box>
  );
}

interface VpnRowModel {
  kind: TunnelKind;
  title: string;
  subtitle: string;
  up: boolean;
}

/**
 * One row per active tunnel, plus an "Off" Tailscale row when the mesh is
 * installed but down. There is no switch: bringing the mesh up needs the
 * flags it was registered with, which the bar does not know.
 */
function vpnRows(list: { kind: TunnelKind; name: string }[], meshPresent: boolean): VpnRowModel[] {
  const rows: VpnRowModel[] = list.map((tunnel) => {
    const title = tunnelKindLabel(tunnel.kind);
    const detail = tunnel.name && tunnel.name !== title ? ` · ${tunnel.name}` : "";

    return { kind: tunnel.kind, title, subtitle: `Connected${detail}`, up: true };
  });

  if (meshPresent && !list.some((tunnel) => tunnel.kind === "mesh")) {
    rows.unshift({ kind: "mesh", title: tunnelKindLabel("mesh"), subtitle: "Off", up: false });
  }

  return rows;
}

function VpnSection() {
  const rows = createComputed([tunnels, meshLinkPresent], vpnRows);

  return (
    <box cssClasses={["panel-section"]} orientation={Gtk.Orientation.VERTICAL} spacing={6}>
      <box cssClasses={["panel-section-head"]}>
        <label cssClasses={["panel-section-label"]} label="VPN" hexpand xalign={0} />
      </box>

      <box cssClasses={["panel-group"]} orientation={Gtk.Orientation.VERTICAL}>
        <For each={rows}>
          {(row) => (
            <box cssClasses={["panel-row", "static"]} spacing={12}>
              <label
                cssClasses={["panel-row-icon", row.up ? "on" : ""]}
                label={tunnelGlyph(row.kind)}
              />
              <box orientation={Gtk.Orientation.VERTICAL} hexpand valign={Gtk.Align.CENTER}>
                <label cssClasses={["panel-row-title"]} label={row.title} xalign={0} />
                <label
                  cssClasses={["panel-row-subtitle"]}
                  label={row.subtitle}
                  xalign={0}
                  maxWidthChars={30}
                  ellipsize={Pango.EllipsizeMode.END}
                />
              </box>
              <label cssClasses={["panel-row-check"]} label={WIFI_ACTIVE} visible={row.up} />
            </box>
          )}
        </For>

        <box cssClasses={["panel-row", "muted"]} visible={rows((r) => r.length === 0)}>
          <label cssClasses={["panel-row-title"]} label="No VPN connected" xalign={0} />
        </box>
      </box>
    </box>
  );
}

/**
 * Open an external settings app and close the panel. The promise settles only
 * when the app exits, and its exit status says nothing the panel can act on.
 */
function launch(command: string): void {
  closeDashboard();
  execAsync([command]).catch(() => {});
}

function SettingsRow({
  glyph,
  label,
  command,
}: {
  glyph: string;
  label: string;
  command: string;
}) {
  return (
    <button cssClasses={["panel-row"]} onClicked={() => launch(command)}>
      <box spacing={12}>
        <label cssClasses={["panel-row-icon"]} label={glyph} />
        <label cssClasses={["panel-row-title"]} label={label} hexpand xalign={0} />
        <label cssClasses={["panel-row-trail"]} label={EXTERNAL_GLYPH} />
      </box>
    </button>
  );
}

/**
 * Body of the Network panel: wired link, Wi-Fi, Bluetooth, VPN and the
 * shortcuts to the full settings apps. Grows with its content and scrolls once
 * it reaches MAX_BODY_HEIGHT.
 */
export function NetworkPanel() {
  return (
    <scrolledwindow
      cssClasses={["panel-scroll"]}
      hscrollbarPolicy={Gtk.PolicyType.NEVER}
      vscrollbarPolicy={Gtk.PolicyType.AUTOMATIC}
      propagateNaturalHeight
      maxContentHeight={MAX_BODY_HEIGHT}
    >
      <box cssClasses={["panel-body"]} orientation={Gtk.Orientation.VERTICAL} spacing={14}>
        <EthernetRow />
        <WifiSection />
        <BluetoothSection />
        <VpnSection />

        <box cssClasses={["panel-separator"]} />

        <box cssClasses={["panel-group"]} orientation={Gtk.Orientation.VERTICAL}>
          <SettingsRow glyph={SETTINGS_GLYPH} label="Network settings" command="nm-connection-editor" />
          <SettingsRow glyph={BT_SETTINGS_GLYPH} label="Bluetooth settings" command="blueman-manager" />
        </box>
      </box>
    </scrolledwindow>
  );
}
