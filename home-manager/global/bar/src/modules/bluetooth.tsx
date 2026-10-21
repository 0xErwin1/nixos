import AstalBluetooth from "gi://AstalBluetooth";
import Pango from "gi://Pango";
import { Gtk } from "ags/gtk4";
import {
  Accessor,
  createBinding,
  createComputed,
  createState,
  For,
  With,
  onCleanup,
} from "ags";
import { createPoll } from "ags/time";
import { execAsync } from "ags/process";

import { BT_ON, BT_OFF, WIFI_ACTIVE, btStateGlyph } from "../glyphs";
import {
  openDashboard,
  closeDashboard,
  dashboardVisible,
  anyPanelOpen,
} from "./dashboard-state";

const bluetooth = AstalBluetooth.get_default();

// BlueZ reports battery as a 0..100 byte, but normalize defensively in case the
// binding hands back a 0..1 fraction.
function normalizeBattery(value: number): number {
  return value > 1 ? Math.round(value) : Math.round(value * 100);
}

// ── Bluetooth audio profile (A2DP high-quality vs HFP headset-with-mic) ────────
// AstalBluetooth has no notion of PipeWire card profiles, so drive them with
// pactl (pipewire-pulse). A BT device's card is `bluez_card.<MAC with : -> _>`.
interface CardProfiles {
  present: boolean;
  active: string;
  mode: "a2dp" | "hfp" | "off" | "none";
  a2dp?: string; // best available High-Quality profile name
  headset?: string; // best available Headset profile name
}

const EMPTY_PROFILES: CardProfiles = { present: false, active: "", mode: "none" };

function cardNameFor(address: string): string {
  return `bluez_card.${address.replaceAll(":", "_")}`;
}

// Codec-agnostic: pick the a2dp-* / headset-* (preferring msbc wideband) profiles
// actually offered by the card rather than hardcoding names.
function parseCard(pactlOutput: string, cardName: string): CardProfiles {
  const block = pactlOutput
    .split(/\nCard #/)
    .find((b) => b.includes(`Name: ${cardName}`));
  if (!block) return EMPTY_PROFILES;

  const section = block.split("Profiles:")[1]?.split("Active Profile:")[0] ?? "";
  const profiles = [
    ...section.matchAll(/^\s+([A-Za-z0-9_+.-]+): .*available: (yes|no)/gm),
  ]
    .map((m) => ({ name: m[1], available: m[2] === "yes" }))
    .filter((p) => p.name !== "off");

  const active = (block.match(/Active Profile: (.+)/)?.[1] ?? "").trim();

  const a2dp =
    profiles.find((p) => p.name.startsWith("a2dp") && p.available)?.name ??
    profiles.find((p) => p.name.startsWith("a2dp"))?.name;
  const headset =
    profiles.find((p) => p.name.includes("msbc") && p.available)?.name ??
    profiles.find((p) => p.name.startsWith("headset") && p.available)?.name ??
    profiles.find((p) => p.name.startsWith("headset"))?.name;

  const mode: CardProfiles["mode"] = active.startsWith("a2dp")
    ? "a2dp"
    : active.startsWith("headset")
      ? "hfp"
      : active === "off"
        ? "off"
        : "none";

  return { present: true, active, mode, a2dp, headset };
}

function setCardProfile(cardName: string, profile: string): void {
  execAsync(["pactl", "set-card-profile", cardName, profile]).catch(() => {});
}

function ProfileControl({ device }: { device: AstalBluetooth.Device }) {
  const cardName = cardNameFor(device.address);

  // Async poll (non-blocking), gated on dashboard visibility so pactl is not
  // spawned while the dashboard is closed.
  const profiles = createPoll<CardProfiles>(
    EMPTY_PROFILES,
    2500,
    async (prev) => {
      if (!dashboardVisible.get()) return prev;
      try {
        return parseCard(await execAsync(["pactl", "list", "cards"]), cardName);
      } catch {
        return EMPTY_PROFILES;
      }
    },
  );

  return (
    <box
      cssClasses={["profile-control"]}
      orientation={Gtk.Orientation.VERTICAL}
      visible={profiles((p) => p.present && (!!p.a2dp || !!p.headset))}
    >
      <label
        xalign={0}
        cssClasses={["profile-label"]}
        label={profiles((p) =>
          p.mode === "a2dp"
            ? "Audio: High Quality (A2DP)"
            : p.mode === "hfp"
              ? "Audio: Headset (HFP · mic)"
              : "Audio: —",
        )}
      />
      <box cssClasses={["profile-buttons"]} spacing={8} halign={Gtk.Align.CENTER}>
        <button
          cssClasses={profiles((p) => [
            "dash-btn",
            "profile-btn",
            p.mode === "a2dp" ? "active" : "",
          ])}
          sensitive={profiles((p) => !!p.a2dp)}
          onClicked={() => {
            const a2dp = profiles.get().a2dp;
            if (a2dp) setCardProfile(cardName, a2dp);
          }}
        >
          <label label="High Quality" />
        </button>
        <button
          cssClasses={profiles((p) => [
            "dash-btn",
            "profile-btn",
            p.mode === "hfp" ? "active" : "",
          ])}
          sensitive={profiles((p) => !!p.headset)}
          onClicked={() => {
            const headset = profiles.get().headset;
            if (headset) setCardProfile(cardName, headset);
          }}
        >
          <label label="Headset" />
        </button>
      </box>
    </box>
  );
}

function sortDevices(
  devices: AstalBluetooth.Device[],
): AstalBluetooth.Device[] {
  const rank = (d: AstalBluetooth.Device) =>
    d.connected ? 0 : d.paired ? 1 : 2;

  return devices
    .filter((d) => d.name || d.alias)
    .sort((a, b) => {
      const r = rank(a) - rank(b);
      if (r !== 0) return r;
      return (a.name || a.address).localeCompare(b.name || b.address);
    });
}

// Device-type glyphs for the Network panel rows, keyed off the BlueZ icon name
// (e.g. "input-keyboard", "audio-headset"). Local until they move to glyphs.ts.
const DEVICE_KEYBOARD = "\u{f030c}"; // md-keyboard
const DEVICE_MOUSE = "\u{f037d}"; // md-mouse
const DEVICE_HEADPHONES = "\u{f02cb}"; // md-headphones
const MORE_GLYPH = "\u{f01d8}"; // md-dots_horizontal
const ADD_GLYPH = "\u{f0415}"; // md-plus

function deviceGlyph(icon: string | null): string {
  const name = icon ?? "";
  if (name.includes("keyboard")) return DEVICE_KEYBOARD;
  if (name.includes("mouse")) return DEVICE_MOUSE;
  if (name.startsWith("audio")) return DEVICE_HEADPHONES;
  return BT_ON;
}

/**
 * One device row: the row itself toggles the connection, and the trailing
 * button reveals an inline action menu. The menu is inline rather than a
 * GtkPopover because a popover is a separate surface, and the panel closes
 * whenever its window stops being the active one.
 *
 * `discovered` rows list devices found by "Add device…": they show only while
 * the user is adding and until the device pairs, so a device moves from the
 * discovered list to the known list without a list rebuild.
 */
function DeviceRow({
  device,
  discovered,
  adding,
  setStatus,
}: {
  device: AstalBluetooth.Device;
  discovered: boolean;
  adding: Accessor<boolean>;
  setStatus: (s: string) => void;
}) {
  const [menuOpen, setMenuOpen] = createState(false);

  const connected = createBinding(device, "connected");
  const connecting = createBinding(device, "connecting");
  const paired = createBinding(device, "paired");
  const battery = createBinding(device, "batteryPercentage");

  const connectNow = () => {
    setStatus(`Connecting ${device.name}…`);
    device.set_trusted(true);
    device.connect_device((_p, res) => {
      try {
        device.connect_device_finish(res);
        setStatus("");
      } catch {
        setStatus("Connect failed");
      }
    });
  };

  const primary = () => {
    if (device.connected) {
      setStatus(`Disconnecting ${device.name}…`);
      device.disconnect_device((_p, res) => {
        try {
          device.disconnect_device_finish(res);
          setStatus("");
        } catch {
          setStatus("Disconnect failed");
        }
      });
      return;
    }

    if (!device.paired) {
      // Just-Works pairing; devices that require a PIN need bluetoothctl.
      setStatus(`Pairing ${device.name}…`);
      device.set_trusted(true);
      const handler = device.connect("notify::paired", () => {
        if (device.paired) {
          device.disconnect(handler);
          connectNow();
        }
      });
      // pair() is synchronous and throws on failure (e.g. no agent / PIN needed).
      try {
        device.pair();
      } catch {
        device.disconnect(handler);
        setStatus("Pairing failed (PIN devices need bluetoothctl)");
      }
      return;
    }

    connectNow();
  };

  const forget = () => {
    setMenuOpen(false);
    bluetooth.adapter?.remove_device(device);
    setStatus("");
  };

  const visible = discovered
    ? createComputed([adding, paired, connected], (a, p, c) => a && !p && !c)
    : createComputed([paired, connected], (p, c) => p || c);

  const subtitle = createComputed(
    [connected, connecting, paired, battery],
    (c, ing, p, b) => {
      if (ing) return "Connecting…";
      if (c) {
        return b > 0 ? `Connected · ${normalizeBattery(b)}% battery` : "Connected";
      }
      return p ? "Not connected" : "Not paired";
    },
  );

  // The profile switcher polls pactl, so it is mounted only while it can be seen.
  const showProfiles = createComputed([connected, menuOpen], (c, m) => c && m);

  return (
    <box cssClasses={["net-device"]} orientation={Gtk.Orientation.VERTICAL} visible={visible}>
      <box cssClasses={["panel-row", "split"]} spacing={4}>
        <button cssClasses={["panel-row-main"]} hexpand onClicked={primary}>
          <box spacing={12}>
            <label
              cssClasses={connected((c) => ["panel-row-icon", c ? "on" : ""])}
              label={deviceGlyph(device.icon)}
            />
            <box orientation={Gtk.Orientation.VERTICAL} hexpand valign={Gtk.Align.CENTER}>
              <label
                cssClasses={["panel-row-title"]}
                label={device.name || device.address}
                xalign={0}
                maxWidthChars={22}
                ellipsize={Pango.EllipsizeMode.END}
              />
              <label cssClasses={["panel-row-subtitle"]} xalign={0} label={subtitle} />
            </box>
            <label cssClasses={["panel-row-check"]} label={WIFI_ACTIVE} visible={connected} />
          </box>
        </button>
        <button
          cssClasses={menuOpen((m) => ["net-more-btn", m ? "open" : ""])}
          tooltipText="More actions"
          valign={Gtk.Align.CENTER}
          onClicked={() => setMenuOpen(!menuOpen.get())}
        >
          <label label={MORE_GLYPH} />
        </button>
      </box>

      <revealer
        transitionType={Gtk.RevealerTransitionType.SLIDE_DOWN}
        transitionDuration={150}
        revealChild={menuOpen}
      >
        <box cssClasses={["net-menu"]} orientation={Gtk.Orientation.VERTICAL} spacing={8}>
          <box spacing={8}>
            <button
              cssClasses={["dash-btn"]}
              label={connected((c) => (c ? "Disconnect" : "Connect"))}
              onClicked={primary}
            />
            <button
              cssClasses={["dash-btn", "danger"]}
              label="Forget"
              visible={paired}
              onClicked={forget}
            />
          </box>
          <With value={showProfiles}>
            {(show: boolean) => (show ? <ProfileControl device={device} /> : <box />)}
          </With>
        </box>
      </revealer>
    </box>
  );
}

function BluetoothSectionInner({ adapter }: { adapter: AstalBluetooth.Adapter }) {
  const [status, setStatus] = createState("");
  const [adding, setAdding] = createState(false);

  const powered = createBinding(bluetooth, "isPowered");
  const discovering = createBinding(adapter, "discovering");
  const devices = createBinding(bluetooth, "devices")(sortDevices);

  // Auto-discover when Bluetooth is powered on (false -> true edge), and stop
  // discovery when it powers off. Mirrors the wifi auto-scan; "Add device…"
  // still starts it by hand.
  let prevPowered = bluetooth.isPowered;
  const unsubscribePowered = powered.subscribe(() => {
    const nowPowered = powered.get();
    if (nowPowered && !prevPowered) {
      adapter.start_discovery();
    } else if (!nowPowered && prevPowered) {
      setAdding(false);
      if (adapter.discovering) adapter.stop_discovery();
    }
    prevPowered = nowPowered;
  });
  onCleanup(unsubscribePowered);

  const stopAdding = () => {
    setAdding(false);
    if (!adapter.discovering) return;

    try {
      adapter.stop_discovery();
    } catch {
      // BlueZ already ended the discovery session.
    }
  };

  // Closing the panel ends an "Add device…" search: nobody is looking at the
  // results, and a running discovery keeps the radio busy.
  const unsubscribeVisible = dashboardVisible.subscribe(() => {
    if (!dashboardVisible.get() && adding.get()) stopAdding();
  });
  onCleanup(unsubscribeVisible);

  const toggleAdding = () => {
    if (adding.get()) {
      stopAdding();
      return;
    }

    setAdding(true);
    if (adapter.discovering) return;

    try {
      adapter.start_discovery();
    } catch {
      setStatus("Scan failed");
    }
  };

  const addHint = createComputed([adding, discovering], (a, d) =>
    a && d ? "Searching for devices…" : "",
  );

  return (
    <box cssClasses={["panel-section"]} orientation={Gtk.Orientation.VERTICAL} spacing={6}>
      <box cssClasses={["panel-section-head"]} spacing={8}>
        <label cssClasses={["panel-section-label"]} label="BLUETOOTH" hexpand xalign={0} />
        <switch
          active={powered}
          valign={Gtk.Align.CENTER}
          onNotifyActive={(self) => {
            if (self.active !== bluetooth.isPowered) bluetooth.toggle();
          }}
        />
      </box>

      <box cssClasses={["panel-group"]} orientation={Gtk.Orientation.VERTICAL}>
        <box cssClasses={["panel-row", "muted"]} spacing={12} visible={powered((p) => !p)}>
          <label cssClasses={["panel-row-icon"]} label={BT_OFF} />
          <label cssClasses={["panel-row-title"]} label="Bluetooth is off" hexpand xalign={0} />
        </box>

        <box orientation={Gtk.Orientation.VERTICAL} visible={powered}>
          <For each={devices}>
            {(device) => (
              <DeviceRow
                device={device}
                discovered={false}
                adding={adding}
                setStatus={setStatus}
              />
            )}
          </For>

          <button cssClasses={["panel-row"]} onClicked={toggleAdding}>
            <box spacing={12}>
              <label cssClasses={["panel-row-icon"]} label={ADD_GLYPH} />
              <label
                cssClasses={["panel-row-title"]}
                label={adding((a) => (a ? "Stop searching" : "Add device…"))}
                hexpand
                xalign={0}
              />
            </box>
          </button>

          <For each={devices}>
            {(device) => (
              <DeviceRow
                device={device}
                discovered={true}
                adding={adding}
                setStatus={setStatus}
              />
            )}
          </For>

          <label
            cssClasses={["panel-empty"]}
            xalign={0}
            visible={addHint((h) => !!h)}
            label={addHint}
          />
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

/** The Bluetooth section of the Network panel: adapter switch, devices and pairing. */
export function BluetoothSection() {
  const adapter = bluetooth.adapter;

  if (!adapter) {
    return (
      <box cssClasses={["panel-section"]} orientation={Gtk.Orientation.VERTICAL} spacing={6}>
        <label cssClasses={["panel-section-label"]} label="BLUETOOTH" xalign={0} />
        <box cssClasses={["panel-group"]}>
          <box cssClasses={["panel-row", "muted"]} spacing={12}>
            <label cssClasses={["panel-row-icon"]} label={BT_OFF} />
            <label cssClasses={["panel-row-title"]} label="No Bluetooth adapter" xalign={0} />
          </box>
        </box>
      </box>
    );
  }

  return <BluetoothSectionInner adapter={adapter} />;
}

export function BluetoothTrigger() {
  const powered = createBinding(bluetooth, "isPowered");
  const connected = createBinding(bluetooth, "isConnected");

  const glyph = createComputed([powered, connected], (p, c) =>
    btStateGlyph(p, c),
  );
  const iconClasses = createComputed([powered, connected], (p, c) => [
    "control-icon",
    "bt-icon",
    !p ? "bt-off" : c ? "bt-connected" : "bt-on",
  ]);
  const tooltip = createComputed([powered, connected], (p, c) =>
    !p ? "Bluetooth off" : c ? "Bluetooth connected" : "Bluetooth on",
  );

  // Press-based (GestureClick) like the other triggers so the second click
  // reliably closes the panel. openDashboard() closes any other open panel via
  // the shared exclusion group.
  const activate = () => {
    if (dashboardVisible.get()) {
      closeDashboard();
    } else {
      openDashboard("bluetooth");
    }
  };

  return (
    <box
      cssClasses={["control-item", "bluetooth", "dash-trigger"]}
      tooltipText={tooltip}
      valign={Gtk.Align.CENTER}
    >
      <Gtk.GestureClick onPressed={activate} />
      <Gtk.EventControllerMotion
        onEnter={() => {
          if (anyPanelOpen()) openDashboard("bluetooth");
        }}
      />
      <label cssClasses={iconClasses} label={glyph} valign={Gtk.Align.CENTER} />
    </box>
  );
}
