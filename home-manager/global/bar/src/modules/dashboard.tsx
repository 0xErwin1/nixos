import app from "ags/gtk4/app";
import { Astal, Gdk, Gtk } from "ags/gtk4";
import { CARD_VALIGN } from "./edge";

import { dashboardVisible, closeDashboard } from "./dashboard-state";
import { NetworkPanel } from "./network-panel";
import { CLOSE_GLYPH } from "../glyphs";

// Network panel: a full-screen OVERLAY layer window whose card hugs the bar's
// edge on the right (near the wifi/bt icons) rather than centered. A fully
// transparent full-screen catcher behind the card closes it on an outside
// click, without dimming the screen. Also closes on Esc, on focus loss and on
// the close button.
export default function Dashboard() {
  const { TOP, BOTTOM, LEFT, RIGHT } = Astal.WindowAnchor;

  return (
    <window
      name="connectivity-dashboard"
      namespace="wl-dashboard"
      visible={dashboardVisible}
      cssClasses={["dashboard-window"]}
      anchor={TOP | BOTTOM | LEFT | RIGHT}
      exclusivity={Astal.Exclusivity.NORMAL}
      layer={Astal.Layer.TOP}
      keymode={Astal.Keymode.ON_DEMAND}
      onNotifyIsActive={(self) => {
        if (!self.isActive) closeDashboard();
      }}
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
          cssClasses={["panel-card"]}
          orientation={Gtk.Orientation.VERTICAL}
          halign={Gtk.Align.END}
          valign={CARD_VALIGN}
          marginTop={8}
          marginBottom={8}
          marginEnd={8}
          spacing={12}
        >
          <box cssClasses={["panel-header"]}>
            <label cssClasses={["panel-title"]} label="Network" hexpand xalign={0} />
            <button cssClasses={["panel-close"]} onClicked={closeDashboard}>
              <label label={CLOSE_GLYPH} />
            </button>
          </box>

          <NetworkPanel />
        </box>
      </overlay>
    </window>
  );
}
