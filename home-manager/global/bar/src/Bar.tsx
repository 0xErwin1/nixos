import app from "ags/gtk4/app";
import GLib from "gi://GLib";
import { Astal, Gtk, Gdk } from "ags/gtk4";
import { For, createBinding, onCleanup } from "ags";

import Left from "./modules/left";
import Center from "./modules/center";
import Right from "./modules/right";

// Bar edge is chosen at startup via the BAR_EDGE env var so the position can be
// tried without rebuilding. "top"/"bottom" produce a horizontal bar spanning
// ~95% of the monitor width; "left"/"right" produce a narrow vertical bar
// spanning ~95% of the height. Anything else falls back to the default "top".
const EDGE = (GLib.getenv("BAR_EDGE") || "top").toLowerCase();
const VERTICAL = EDGE === "left" || EDGE === "right";

const EDGE_GAP = 8;
const LONG_AXIS_FRACTION = 0.025;

function anchorFor(edge: string): number {
  const { TOP, BOTTOM, LEFT, RIGHT } = Astal.WindowAnchor;
  switch (edge) {
    case "top":
      return TOP | LEFT | RIGHT;
    case "left":
      return LEFT | TOP | BOTTOM;
    case "right":
      return RIGHT | TOP | BOTTOM;
    case "bottom":
    default:
      return BOTTOM | LEFT | RIGHT;
  }
}

function Bar({ gdkmonitor }: { gdkmonitor: Gdk.Monitor }) {
  let win: Astal.Window;
  onCleanup(() => win?.destroy());

  const geo = gdkmonitor.get_geometry();
  const longMargin = Math.round(
    (VERTICAL ? geo.height : geo.width) * LONG_AXIS_FRACTION,
  );

  return (
    <window
      $={(self) => (win = self)}
      visible
      namespace="epsilon-bar"
      name={`epsilon-bar-${gdkmonitor.connector}`}
      cssClasses={["bar-window", VERTICAL ? "vertical" : "horizontal"]}
      gdkmonitor={gdkmonitor}
      exclusivity={Astal.Exclusivity.EXCLUSIVE}
      anchor={anchorFor(EDGE)}
      marginTop={VERTICAL ? longMargin : EDGE === "top" ? EDGE_GAP : 0}
      marginBottom={VERTICAL ? longMargin : EDGE === "bottom" ? EDGE_GAP : 0}
      marginLeft={VERTICAL ? (EDGE === "left" ? EDGE_GAP : 0) : longMargin}
      marginRight={VERTICAL ? (EDGE === "right" ? EDGE_GAP : 0) : longMargin}
      application={app}
    >
      <centerbox
        cssClasses={["bar", VERTICAL ? "vertical" : "horizontal"]}
        orientation={
          VERTICAL ? Gtk.Orientation.VERTICAL : Gtk.Orientation.HORIZONTAL
        }
      >
        <box $type="start" cssClasses={["group", "group-start"]}>
          <Left vertical={VERTICAL} />
        </box>
        <box $type="center" cssClasses={["group", "group-center"]}>
          <Center vertical={VERTICAL} />
        </box>
        <box $type="end" cssClasses={["group", "group-end"]}>
          <Right vertical={VERTICAL} />
        </box>
      </centerbox>
    </window>
  );
}

export default function () {
  const monitors = createBinding(app, "monitors");
  return (
    <For each={monitors} cleanup={(win) => (win as Gtk.Window).destroy()}>
      {(monitor) => <Bar gdkmonitor={monitor} />}
    </For>
  );
}
