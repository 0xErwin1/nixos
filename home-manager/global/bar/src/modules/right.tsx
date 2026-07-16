import GLib from "gi://GLib";
import AstalWp from "gi://AstalWp";
import { createBinding, With } from "ags";
import { Gtk } from "ags/gtk4";
import { createPoll } from "ags/time";
import { exec } from "ags/process";

import {
  batteryGlyph,
  volumeGlyph,
  brightnessGlyph,
  MIC_MUTED,
  MIC_UNMUTED,
} from "../glyphs";
import Voxtype from "./voxtype";
import Tray from "./tray";
import { WifiTrigger } from "./wifi";
import { BluetoothTrigger } from "./bluetooth";
import { NotificationBell } from "./notifications";

interface Props {
  vertical: boolean;
}

function Brightness({ vertical }: Props) {
  // Astal ships no reliable brightness service, so poll brightnessctl like the
  // eww bar did. Reports 0 when there is no backlight (e.g. a desktop).
  const percent = createPoll(0, 2000, () => {
    try {
      const max = Number(exec("brightnessctl max"));
      if (!max) return 0;
      return Math.round((Number(exec("brightnessctl get")) * 100) / max);
    } catch {
      return 0;
    }
  });

  return (
    <box cssClasses={["control-item", "brightness"]} valign={Gtk.Align.CENTER}>
      <label
        cssClasses={["control-icon"]}
        label={percent(brightnessGlyph)}
        valign={Gtk.Align.CENTER}
      />
      {!vertical && (
        <label
          cssClasses={["control-percent"]}
          label={percent((p) => `${p}%`)}
          valign={Gtk.Align.CENTER}
        />
      )}
    </box>
  );
}

interface BatteryInfo {
  percent: number;
  charging: boolean;
}

// The UPower DisplayDevice exposed by AstalBattery.get_default() reports
// is-present=false / 0% for BAT0 on this host, so read sysfs directly the way
// the eww bar does to stay faithful to what the user sees.
function readBattery(): BatteryInfo | null {
  try {
    const [ok, bytes] = GLib.file_get_contents(
      "/sys/class/power_supply/BAT0/capacity",
    );
    if (!ok) return null;

    const percent = parseInt(new TextDecoder().decode(bytes).trim(), 10);
    if (Number.isNaN(percent)) return null;

    const [okStatus, statusBytes] = GLib.file_get_contents(
      "/sys/class/power_supply/BAT0/status",
    );
    const status = okStatus ? new TextDecoder().decode(statusBytes).trim() : "";

    return { percent, charging: status === "Charging" };
  } catch {
    return null;
  }
}

function Battery({ vertical }: Props) {
  const info = createPoll<BatteryInfo | null>(readBattery(), 10000, readBattery);

  const present = info((i) => i !== null);
  const glyph = info((i) => (i ? batteryGlyph(i.percent, i.charging) : ""));
  const percentText = info((i) => (i ? `${i.percent}%` : ""));

  return (
    <box
      cssClasses={["control-item", "battery"]}
      visible={present}
      valign={Gtk.Align.CENTER}
    >
      <label
        cssClasses={["control-icon"]}
        label={glyph}
        valign={Gtk.Align.CENTER}
      />
      {!vertical && (
        <label
          cssClasses={["control-percent"]}
          label={percentText}
          valign={Gtk.Align.CENTER}
        />
      )}
    </box>
  );
}

interface VolumeInfo {
  percent: number;
  muted: boolean;
}

// AstalWp.defaultSpeaker can stay pinned to the wrong sink when a bluetooth
// headset exposes several nodes: e.g. the XM5 keeps its A2DP node around while a
// call switches the real default to its HFP node, so the binding kept reporting
// the A2DP volume (94%) instead of the sink actually being heard (33%). Poll the
// real default sink instead — the same one the volume keys and desktop control.
function readVolume(): VolumeInfo {
  try {
    const out = exec("wpctl get-volume @DEFAULT_AUDIO_SINK@");
    const match = out.match(/Volume:\s*([0-9.]+)/);
    const percent = match ? Math.round(parseFloat(match[1]) * 100) : 0;

    return { percent, muted: /\[MUTED\]/.test(out) };
  } catch {
    return { percent: 0, muted: false };
  }
}

function Volume({ vertical }: Props) {
  const info = createPoll<VolumeInfo>(readVolume(), 1000, readVolume);

  return (
    <box cssClasses={["control-item", "volume"]} valign={Gtk.Align.CENTER}>
      <label
        cssClasses={["control-icon"]}
        label={info((i) => volumeGlyph(i.percent, i.muted))}
        valign={Gtk.Align.CENTER}
      />
      {!vertical && (
        <label
          cssClasses={["control-percent"]}
          label={info((i) => `${i.percent}%`)}
          valign={Gtk.Align.CENTER}
        />
      )}
    </box>
  );
}

function MicrophoneInner({ mic }: { mic: AstalWp.Endpoint }) {
  const mute = createBinding(mic, "mute");

  return (
    <box cssClasses={["control-item", "microphone"]} valign={Gtk.Align.CENTER}>
      <label
        cssClasses={mute((m) => [
          "control-icon",
          m ? "microphone-muted" : "microphone-active",
        ])}
        label={mute((m) => (m ? MIC_MUTED : MIC_UNMUTED))}
        valign={Gtk.Align.CENTER}
      />
    </box>
  );
}

function Microphone() {
  const mic = createBinding(
    AstalWp.get_default()!.audio,
    "defaultMicrophone",
  );

  return (
    <With value={mic}>
      {(m: AstalWp.Endpoint | null) =>
        m ? <MicrophoneInner mic={m} /> : <box visible={false} />
      }
    </With>
  );
}

export default function Right({ vertical }: Props) {
  const orientation = vertical
    ? Gtk.Orientation.VERTICAL
    : Gtk.Orientation.HORIZONTAL;

  // No box spacing: islands self-space via their CSS margins, so the collapsed
  // voxtype revealer (0 width when idle) leaves no phantom gap. Placed first so
  // it grows leftward into the empty area when revealed, without shifting the
  // right-anchored controls/clock or the centered tray.
  return (
    <box
      orientation={orientation}
      halign={vertical ? Gtk.Align.CENTER : Gtk.Align.END}
      valign={vertical ? Gtk.Align.END : Gtk.Align.CENTER}
    >
      <Voxtype vertical={vertical} />
      <box
        cssClasses={["island", "controls"]}
        orientation={orientation}
        spacing={vertical ? 6 : 9}
        valign={Gtk.Align.CENTER}
      >
        <Brightness vertical={vertical} />
        <Battery vertical={vertical} />
        <Volume vertical={vertical} />
        <Microphone />
        <BluetoothTrigger />
        <WifiTrigger />
        <NotificationBell />
      </box>
      <Tray vertical={vertical} />
    </box>
  );
}
