import GLib from "gi://GLib";
import AstalWp from "gi://AstalWp";
import AstalNetwork from "gi://AstalNetwork";
import { createBinding, createComputed, With } from "ags";
import { Gtk } from "ags/gtk4";
import { createPoll } from "ags/time";
import { exec } from "ags/process";

import {
  batteryGlyph,
  volumeGlyph,
  brightnessGlyph,
  MIC_MUTED,
  MIC_UNMUTED,
  WIFI_ETHERNET,
  WIFI_WIFI,
  WIFI_DISCONNECTED,
} from "../glyphs";
import Voxtype from "./voxtype";

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

// Bind to the currently active speaker: AstalWp.audio.defaultSpeaker changes
// when the default output switches (bluetooth / USB DAC / internal), so the
// widget must re-derive against the live endpoint instead of a stale one
// captured at construction. AstalWp `volume` is the same 0..1 scale wpctl
// reports (0.30 -> 30%); it can exceed 1.0 for over-amplification, shown as-is.
function SpeakerInner({
  speaker,
  vertical,
}: {
  speaker: AstalWp.Endpoint;
  vertical: boolean;
}) {
  const volume = createBinding(speaker, "volume");
  const mute = createBinding(speaker, "mute");

  const glyph = createComputed([volume, mute], (v, m) =>
    volumeGlyph(Math.round(v * 100), m),
  );

  return (
    <box cssClasses={["control-item", "volume"]} valign={Gtk.Align.CENTER}>
      <label
        cssClasses={["control-icon"]}
        label={glyph}
        valign={Gtk.Align.CENTER}
      />
      {!vertical && (
        <label
          cssClasses={["control-percent"]}
          label={volume((v) => `${Math.round(v * 100)}%`)}
          valign={Gtk.Align.CENTER}
        />
      )}
    </box>
  );
}

function Volume({ vertical }: Props) {
  const speaker = createBinding(AstalWp.get_default()!.audio, "defaultSpeaker");

  return (
    <With value={speaker}>
      {(sp: AstalWp.Endpoint | null) =>
        sp ? (
          <SpeakerInner speaker={sp} vertical={vertical} />
        ) : (
          <box visible={false} />
        )
      }
    </With>
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

function Wifi() {
  const network = AstalNetwork.get_default();
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
    <box
      cssClasses={["control-item", "wifi"]}
      tooltipText={tooltip}
      valign={Gtk.Align.CENTER}
    >
      <label
        cssClasses={["control-icon", "wifi-icon"]}
        label={glyph}
        valign={Gtk.Align.CENTER}
      />
    </box>
  );
}

function Clock({ vertical }: Props) {
  if (vertical) {
    const hh = createPoll(
      "",
      1000,
      () => GLib.DateTime.new_now_local().format("%H")!,
    );
    const mm = createPoll(
      "",
      1000,
      () => GLib.DateTime.new_now_local().format("%M")!,
    );

    return (
      <box
        cssClasses={["date", "date-vertical"]}
        orientation={Gtk.Orientation.VERTICAL}
        valign={Gtk.Align.CENTER}
      >
        <label cssClasses={["time"]} label={hh} valign={Gtk.Align.CENTER} />
        <label cssClasses={["time"]} label={mm} valign={Gtk.Align.CENTER} />
      </box>
    );
  }

  const clock = createPoll(
    "",
    1000,
    () => GLib.DateTime.new_now_local().format("%H:%M │ %b %d, %Y")!,
  );

  return (
    <box cssClasses={["date"]} valign={Gtk.Align.CENTER}>
      <label cssClasses={["time"]} label={clock} valign={Gtk.Align.CENTER} />
    </box>
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
        spacing={vertical ? 6 : 12}
        valign={Gtk.Align.CENTER}
      >
        <Brightness vertical={vertical} />
        <Battery vertical={vertical} />
        <Volume vertical={vertical} />
        <Microphone />
        <Wifi />
      </box>
      <box
        cssClasses={["island", "clock-island"]}
        orientation={orientation}
        valign={Gtk.Align.CENTER}
      >
        <Clock vertical={vertical} />
      </box>
    </box>
  );
}
