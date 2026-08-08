// Derived network status shared by the bar trigger and the Wi-Fi panel.
//
// AstalNetwork covers the medium (wired/wifi), signal strength and NetworkManager's
// connectivity check, which is what separates "associated" from "actually reaching
// the internet". It does not model VPNs at all, so tunnels are read straight from
// NM.Client's active connections: WireGuard profiles report a "wireguard" connection
// type with `vpn` false, while plugin-based VPNs report `vpn` true.
import AstalNetwork from "gi://AstalNetwork";
import NM from "gi://NM";
import { createBinding, createComputed } from "ags";

import {
  ETHERNET,
  INTERNET_OFF,
  INTERNET_PORTAL,
  INTERNET_SYNC,
  WIFI_OFF,
  WIFI_PORTAL,
  WIFI_SYNC,
  WIFI_UNAVAILABLE,
  wifiSignalGlyph,
  wifiSignalAlertGlyph,
} from "../glyphs";

const network = AstalNetwork.get_default();

export type NetMedium = "wired" | "wifi" | "none";

/** How far traffic actually gets, independent of which medium carries it. */
export type NetReach =
  | "off"
  | "disconnected"
  | "connecting"
  | "portal"
  | "no-internet"
  | "online";

export interface NetStatus {
  medium: NetMedium;
  reach: NetReach;
  /** Wi-Fi signal in percent; 0 for every other medium. */
  strength: number;
  ssid: string | null;
  /** Wired link speed in Mbit/s; 0 when not on wired. */
  wiredSpeed: number;
  /** Names of the active VPN or WireGuard profiles, empty when no tunnel is up. */
  vpn: string[];
}

const CONNECTING_DEVICE_STATES = new Set<AstalNetwork.DeviceState>([
  AstalNetwork.DeviceState.PREPARE,
  AstalNetwork.DeviceState.CONFIG,
  AstalNetwork.DeviceState.NEED_AUTH,
  AstalNetwork.DeviceState.IP_CONFIG,
  AstalNetwork.DeviceState.IP_CHECK,
  AstalNetwork.DeviceState.SECONDARIES,
]);

function isActivated(state: AstalNetwork.DeviceState): boolean {
  return state === AstalNetwork.DeviceState.ACTIVATED;
}

/**
 * Resolve reachability for an already-activated device.
 *
 * NetworkManager's connectivity check is authoritative when it has run; UNKNOWN
 * means the check is disabled or has not completed, so the device's own view of
 * having a default route is used instead.
 */
function activatedReach(
  internet: AstalNetwork.Internet,
  connectivity: AstalNetwork.Connectivity,
): NetReach {
  if (internet === AstalNetwork.Internet.CONNECTING) return "connecting";

  switch (connectivity) {
    case AstalNetwork.Connectivity.FULL:
      return "online";
    case AstalNetwork.Connectivity.PORTAL:
      return "portal";
    case AstalNetwork.Connectivity.LIMITED:
    case AstalNetwork.Connectivity.NONE:
      return "no-internet";
    default:
      return internet === AstalNetwork.Internet.CONNECTED
        ? "online"
        : "no-internet";
  }
}

function deriveStatus(
  wired: AstalNetwork.Wired | null,
  wifi: AstalNetwork.Wifi | null,
  connectivity: AstalNetwork.Connectivity,
  vpn: string[],
): NetStatus {
  const base = { strength: 0, ssid: null, wiredSpeed: 0, vpn } as const;

  if (wired && isActivated(wired.state)) {
    return {
      ...base,
      medium: "wired",
      reach: activatedReach(wired.internet, connectivity),
      wiredSpeed: wired.speed,
    };
  }

  if (wifi && isActivated(wifi.state)) {
    return {
      ...base,
      medium: "wifi",
      reach: activatedReach(wifi.internet, connectivity),
      strength: wifi.strength,
      ssid: wifi.ssid,
    };
  }

  if (wired && CONNECTING_DEVICE_STATES.has(wired.state)) {
    return { ...base, medium: "wired", reach: "connecting" };
  }

  if (wifi && CONNECTING_DEVICE_STATES.has(wifi.state)) {
    return { ...base, medium: "wifi", reach: "connecting", ssid: wifi.ssid };
  }

  // Nothing is up: the radio being off is a distinct state worth its own icon,
  // but only when there is no wired fallback to report instead.
  if (wifi && !wifi.enabled) return { ...base, medium: "none", reach: "off" };

  return { ...base, medium: "none", reach: "disconnected" };
}

export function networkGlyph(status: NetStatus): string {
  if (status.medium === "wired") {
    switch (status.reach) {
      case "connecting":
        return INTERNET_SYNC;
      case "portal":
        return INTERNET_PORTAL;
      case "no-internet":
        return INTERNET_OFF;
      default:
        return ETHERNET;
    }
  }

  if (status.medium === "wifi") {
    switch (status.reach) {
      case "connecting":
        return WIFI_SYNC;
      case "portal":
        return WIFI_PORTAL;
      case "no-internet":
        return wifiSignalAlertGlyph(status.strength);
      default:
        return wifiSignalGlyph(status.strength);
    }
  }

  return status.reach === "off" ? WIFI_OFF : WIFI_UNAVAILABLE;
}

/** Short label for the reach state, used by the tooltip and the panel card. */
export function reachLabel(status: NetStatus): string {
  switch (status.reach) {
    case "off":
      return "Wi-Fi off";
    case "disconnected":
      return "Disconnected";
    case "connecting":
      return "Connecting…";
    case "portal":
      return "Sign-in required";
    case "no-internet":
      return "No internet";
    default:
      return "Online";
  }
}

export function statusTooltip(status: NetStatus): string {
  const lines: string[] = [];

  if (status.medium === "wifi") {
    lines.push(status.ssid ? `Wi-Fi: ${status.ssid}` : "Wi-Fi");
    if (status.strength > 0) lines.push(`Signal: ${status.strength}%`);
  } else if (status.medium === "wired") {
    lines.push(
      status.wiredSpeed > 0 ? `Wired: ${status.wiredSpeed} Mb/s` : "Wired",
    );
  } else {
    lines.push("No connection");
  }

  lines.push(reachLabel(status));
  if (status.vpn.length > 0) lines.push(`VPN: ${status.vpn.join(", ")}`);

  return lines.join("\n");
}

function activeTunnels(client: NM.Client): string[] {
  return client
    .get_active_connections()
    .filter(
      (ac) =>
        (ac.get_vpn() || ac.get_connection_type() === "wireguard") &&
        ac.get_state() === NM.ActiveConnectionState.ACTIVATED,
    )
    .map((ac) => ac.get_id() ?? "VPN");
}

/**
 * Reactive network status, shared by the bar trigger and the panel.
 *
 * Every source is a GObject property, so the value recomputes on NetworkManager
 * events with no polling. Tunnels come from the client's active-connection list,
 * which changes whenever a tunnel is brought up or torn down. It lives at module
 * scope because the status is global and outlives any single widget.
 */
function createNetworkStatus() {
  const connectivity = createBinding(network, "connectivity");
  const vpn = createBinding(network.client, "activeConnections")(() =>
    activeTunnels(network.client),
  );

  const wired = network.wired;
  const wifi = network.wifi;

  // A binding per device property the status depends on: AstalNetwork emits
  // notify on each of these individually, and reading the device object alone
  // would not re-run the computation.
  const sources = [
    connectivity,
    vpn,
    ...(wired
      ? [
          createBinding(wired, "state"),
          createBinding(wired, "internet"),
          createBinding(wired, "speed"),
        ]
      : []),
    ...(wifi
      ? [
          createBinding(wifi, "state"),
          createBinding(wifi, "internet"),
          createBinding(wifi, "strength"),
          createBinding(wifi, "ssid"),
          createBinding(wifi, "enabled"),
        ]
      : []),
  ];

  return createComputed(sources, () =>
    deriveStatus(wired, wifi, connectivity.get(), vpn.get()),
  );
}

export const networkStatus = createNetworkStatus();
