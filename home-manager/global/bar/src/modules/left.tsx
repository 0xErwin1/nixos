import AstalHyprland from "gi://AstalHyprland";
import { createBinding, createComputed } from "ags";
import { Gtk } from "ags/gtk4";
import { createPoll } from "ags/time";
import { exec } from "ags/process";

import {
  OS_NIXOS,
  WORKSPACE_GLYPHS,
  WINDOW_ICON,
  FULLSCREEN_ICON,
} from "../glyphs";
import { Separator } from "./common";

const hypr = AstalHyprland.get_default();

const WORKSPACE_IDS = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10];

interface Props {
  vertical: boolean;
}

function OsIcon() {
  return (
    <label cssClasses={["os-icon"]} label={OS_NIXOS} valign={Gtk.Align.CENTER} />
  );
}

function Workspaces({ vertical }: Props) {
  const workspaces = createBinding(hypr, "workspaces");
  const focused = createBinding(hypr, "focusedWorkspace");

  return (
    <box
      cssClasses={["workspaces"]}
      orientation={vertical ? Gtk.Orientation.VERTICAL : Gtk.Orientation.HORIZONTAL}
      spacing={vertical ? 4 : 6}
      valign={Gtk.Align.CENTER}
    >
      {WORKSPACE_IDS.map((id) => (
        <button
          cssClasses={createComputed([workspaces, focused], (wss, fw) => {
            const ws = wss.find((w) => w.get_id() === id);
            const occupied = ws ? ws.get_clients().length > 0 : false;
            const current = fw?.get_id() === id;

            const state = current ? "current" : occupied ? "occupied" : "empty";
            return ["workspace-entry", state];
          })}
          onClicked={() => hypr.dispatch("workspace", String(id))}
        >
          <label label={WORKSPACE_GLYPHS[id]} valign={Gtk.Align.CENTER} />
        </button>
      ))}
    </box>
  );
}

interface WsInfo {
  windows: number;
  fullscreen: boolean;
}

// hyprctl activeworkspace is the same source the eww bar polled: it reports the
// live window count and fullscreen flag for the focused workspace, which the
// AstalHyprland focused-workspace binding did not update reliably on window
// open/close. hyprctl is inherited from the running Hyprland session's PATH.
function readActiveWorkspace(): WsInfo {
  try {
    const info = JSON.parse(exec("hyprctl activeworkspace -j"));
    return {
      windows: Number(info.windows) || 0,
      fullscreen: Boolean(info.hasfullscreen),
    };
  } catch {
    return { windows: 0, fullscreen: false };
  }
}

function WsState({ vertical }: Props) {
  const info = createPoll<WsInfo>(readActiveWorkspace(), 1000, readActiveWorkspace);

  const windowCount = info((i) => String(i.windows));
  const fullscreen = info((i) => (i.fullscreen ? FULLSCREEN_ICON : ""));

  return (
    <box
      cssClasses={["workspace-state"]}
      orientation={vertical ? Gtk.Orientation.VERTICAL : Gtk.Orientation.HORIZONTAL}
      valign={Gtk.Align.CENTER}
    >
      <label
        cssClasses={["window-icon"]}
        label={WINDOW_ICON}
        valign={Gtk.Align.CENTER}
      />
      <label
        cssClasses={["window-count"]}
        label={windowCount}
        valign={Gtk.Align.CENTER}
      />
      <label
        cssClasses={["fullscreen-state"]}
        label={fullscreen}
        valign={Gtk.Align.CENTER}
      />
    </box>
  );
}

export default function Left({ vertical }: Props) {
  return (
    <box
      cssClasses={["island", "island-left"]}
      orientation={vertical ? Gtk.Orientation.VERTICAL : Gtk.Orientation.HORIZONTAL}
      spacing={vertical ? 6 : 4}
      valign={Gtk.Align.CENTER}
    >
      <OsIcon />
      {!vertical && <Separator />}
      <Workspaces vertical={vertical} />
      {!vertical && <Separator />}
      <WsState vertical={vertical} />
    </box>
  );
}
