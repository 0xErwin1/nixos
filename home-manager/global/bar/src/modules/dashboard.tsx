import app from "ags/gtk4/app";
import { Astal, Gdk, Gtk } from "ags/gtk4";

import {
  DashboardTab,
  dashboardVisible,
  activeTab,
  setActiveTab,
  closeDashboard,
} from "./dashboard-state";
import { WifiTab } from "./wifi";
import { BluetoothTab } from "./bluetooth";
import { WIFI_WIFI, BT_ON, CLOSE_GLYPH } from "../glyphs";

function TabButton({
  tab,
  label,
  glyph,
}: {
  tab: DashboardTab;
  label: string;
  glyph: string;
}) {
  return (
    <button
      cssClasses={activeTab((t) => ["dash-tab", t === tab ? "active" : ""])}
      onClicked={() => setActiveTab(tab)}
    >
      <box spacing={10}>
        <label cssClasses={["dash-tab-glyph"]} label={glyph} />
        <label label={label} />
      </box>
    </button>
  );
}

// Connectivity dashboard: a full-screen OVERLAY layer window whose card drops
// down from the top-right (under the bar, near the wifi/bt icons) rather than
// centered. A fully transparent full-screen catcher behind the card closes it on
// an outside click, without dimming the screen. Also closes on Esc and the
// close button. Both tabs stay mounted and are toggled by visibility so each
// keeps its state across tab switches.
export default function Dashboard() {
  const { TOP, BOTTOM, LEFT, RIGHT } = Astal.WindowAnchor;

  return (
    <window
      name="connectivity-dashboard"
      namespace="epsilon-dashboard"
      visible={dashboardVisible}
      cssClasses={["dashboard-window"]}
      anchor={TOP | BOTTOM | LEFT | RIGHT}
      exclusivity={Astal.Exclusivity.IGNORE}
      layer={Astal.Layer.TOP}
      keymode={Astal.Keymode.ON_DEMAND}
      application={app}
    >
      <Gtk.EventControllerKey
        onKeyPressed={(_controller, keyval: number) => {
          if (keyval === Gdk.KEY_Escape) closeDashboard();
        }}
      />
      <overlay>
        <button cssClasses={["dashboard-backdrop"]} onClicked={closeDashboard} />
        <box
          $type="overlay"
          cssClasses={["dashboard-card"]}
          orientation={Gtk.Orientation.VERTICAL}
          halign={Gtk.Align.END}
          valign={Gtk.Align.START}
          spacing={12}
        >
          <box cssClasses={["dash-header"]}>
            <box hexpand />
            <button cssClasses={["dash-close"]} onClicked={closeDashboard}>
              <label label={CLOSE_GLYPH} />
            </button>
          </box>

          <box cssClasses={["dash-content"]} hexpand vexpand>
            <box visible={activeTab((t) => t === "wifi")} hexpand vexpand>
              <WifiTab />
            </box>
            <box visible={activeTab((t) => t === "bluetooth")} hexpand vexpand>
              <BluetoothTab />
            </box>
          </box>

          <box cssClasses={["dashboard-tabs"]} halign={Gtk.Align.CENTER} spacing={10}>
            <TabButton tab="wifi" label="Wi-Fi" glyph={WIFI_WIFI} />
            <TabButton tab="bluetooth" label="Bluetooth" glyph={BT_ON} />
          </box>
        </box>
      </overlay>
    </window>
  );
}
