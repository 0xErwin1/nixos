import AstalBluetooth from "gi://AstalBluetooth";
import Pango from "gi://Pango";
import { Gtk } from "ags/gtk4";
import {
  createBinding,
  createComputed,
  createState,
  For,
  With,
  onCleanup,
} from "ags";
import { createPoll } from "ags/time";
import { execAsync } from "ags/process";

import {
  BT_ON,
  BT_CONNECTED,
  BT_OFF,
  FORGET_GLYPH,
  WIFI_REFRESH,
  btStateGlyph,
} from "../glyphs";
import { openDashboard, dashboardVisible } from "./dashboard-state";

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

function DeviceRow({
  device,
  setStatus,
}: {
  device: AstalBluetooth.Device;
  setStatus: (s: string) => void;
}) {
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
    bluetooth.adapter?.remove_device(device);
    setStatus("");
  };

  const subtitle = createComputed(
    [connected, connecting, paired, battery],
    (c, ing, p, b) => {
      if (ing) return "Connecting…";
      if (c) return b > 0 ? `Connected · ${normalizeBattery(b)}%` : "Connected";
      if (p) return "Paired";
      return device.address;
    },
  );

  return (
    <box cssClasses={["list-row", "bt-row"]} spacing={8}>
      <button cssClasses={["bt-row-main"]} hexpand onClicked={primary}>
        <box spacing={10}>
          <label
            cssClasses={connected((c) => [
              "bt-dev-icon",
              c ? "bt-connected" : "bt-on",
            ])}
            label={connected((c) => (c ? BT_CONNECTED : BT_ON))}
          />
          <box orientation={Gtk.Orientation.VERTICAL} hexpand halign={Gtk.Align.START}>
            <label
              cssClasses={["bt-dev-name"]}
              label={device.name || device.address}
              xalign={0}
              maxWidthChars={24}
              ellipsize={Pango.EllipsizeMode.END}
            />
            <label cssClasses={["bt-dev-sub"]} xalign={0} label={subtitle} />
          </box>
        </box>
      </button>
      <button
        cssClasses={["dash-btn", "danger", "icon-btn"]}
        visible={paired}
        tooltipText="Forget"
        valign={Gtk.Align.CENTER}
        onClicked={forget}
      >
        <label label={FORGET_GLYPH} />
      </button>
    </box>
  );
}

function ConnectedFocus({ device }: { device: AstalBluetooth.Device }) {
  const battery = createBinding(device, "batteryPercentage");

  return (
    <box orientation={Gtk.Orientation.VERTICAL}>
      <label cssClasses={["focus-glyph", "bt-focus-glyph"]} label={BT_CONNECTED} />
      <label cssClasses={["focus-title"]} label={device.name || device.address} />
      <label cssClasses={["focus-subtitle"]} label="Connected" />
      <box cssClasses={["focus-meta"]} orientation={Gtk.Orientation.VERTICAL}>
        <label
          xalign={0}
          label={battery((b) =>
            b > 0 ? `Battery: ${normalizeBattery(b)}%` : "Battery: —",
          )}
        />
        <label xalign={0} label={`MAC: ${device.address}`} />
      </box>
      <ProfileControl device={device} />
    </box>
  );
}

function BluetoothTabInner({ adapter }: { adapter: AstalBluetooth.Adapter }) {
  const [status, setStatus] = createState("");

  const powered = createBinding(bluetooth, "isPowered");
  const discovering = createBinding(adapter, "discovering");
  const devices = createBinding(bluetooth, "devices")(sortDevices);

  const focusDevice = createBinding(bluetooth, "isConnected")(
    () => bluetooth.get_devices().find((d) => d.connected) ?? null,
  );

  const emptyText = createComputed(
    [powered, discovering, devices],
    (p, d, devs) =>
      !p
        ? "Bluetooth is off"
        : devs.length > 0
          ? ""
          : d
            ? "Scanning…"
            : "No devices found",
  );

  // Auto-discover when Bluetooth is powered on (false -> true edge), and stop
  // discovery when it powers off. Mirrors the wifi auto-scan; the manual Scan
  // button still works.
  let prevPowered = bluetooth.isPowered;
  const unsubscribePowered = powered.subscribe(() => {
    const nowPowered = powered.get();
    if (nowPowered && !prevPowered) {
      adapter.start_discovery();
    } else if (!nowPowered && prevPowered && adapter.discovering) {
      adapter.stop_discovery();
    }
    prevPowered = nowPowered;
  });
  onCleanup(unsubscribePowered);

  return (
    <box
      cssClasses={["tab", "bt-tab"]}
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
        <With value={focusDevice}>
          {(device: AstalBluetooth.Device | null) =>
            device ? (
              <ConnectedFocus device={device} />
            ) : (
              <box orientation={Gtk.Orientation.VERTICAL}>
                <label
                  cssClasses={["focus-glyph", "bt-focus-glyph"]}
                  label={powered((p) => (p ? BT_ON : BT_OFF))}
                />
                <label
                  cssClasses={["focus-title"]}
                  label={powered((p) => (p ? "No device connected" : "Bluetooth Off"))}
                />
              </box>
            )
          }
        </With>
      </box>

      <box cssClasses={["actions-row"]} halign={Gtk.Align.CENTER} spacing={14}>
        <box cssClasses={["action-toggle"]} spacing={8}>
          <label label="Bluetooth" />
          <switch
            active={powered}
            valign={Gtk.Align.CENTER}
            onNotifyActive={(self) => {
              if (self.active !== bluetooth.isPowered) bluetooth.toggle();
            }}
          />
        </box>
        <button
          cssClasses={["dash-btn"]}
          sensitive={powered}
          onClicked={() =>
            adapter.discovering
              ? adapter.stop_discovery()
              : adapter.start_discovery()
          }
        >
          <box spacing={6}>
            <label label={WIFI_REFRESH} />
            <label label="Scan" />
          </box>
        </button>
        <label
          cssClasses={["scan-indicator"]}
          label={discovering((d) => (d ? "Scanning…" : ""))}
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
          <box cssClasses={["bt-list"]} orientation={Gtk.Orientation.VERTICAL}>
            <For each={devices}>
              {(device) => <DeviceRow device={device} setStatus={setStatus} />}
            </For>
          </box>
        </scrolledwindow>
      </box>

      <label
        cssClasses={["statusline"]}
        xalign={0}
        visible={status((s) => !!s)}
        label={status}
      />
    </box>
  );
}

export function BluetoothTab() {
  const adapter = bluetooth.adapter;

  if (!adapter) {
    return (
      <box cssClasses={["tab", "bt-tab"]}>
        <label label="No Bluetooth adapter" />
      </box>
    );
  }

  return <BluetoothTabInner adapter={adapter} />;
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

  return (
    <button
      cssClasses={["control-item", "bluetooth", "dash-trigger"]}
      tooltipText={tooltip}
      valign={Gtk.Align.CENTER}
      onClicked={() => openDashboard("bluetooth")}
    >
      <label cssClasses={iconClasses} label={glyph} valign={Gtk.Align.CENTER} />
    </button>
  );
}
