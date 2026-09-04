// Active tunnels, merged from the two places they can live on these hosts.
//
// NetworkManager owns profile-based tunnels — its OpenVPN plugin and native
// WireGuard profiles — and those are reactive: NM.Client's active-connection
// list changes as they come up and go down. tailscaled, wg-quick and a
// hand-started openvpn are invisible to NM, so they are discovered by a slow
// poll instead. The mesh state comes from `tailscale status` because it is the
// only source that separates "logged in and routing" from "tailscale0 still
// present after `tailscale down`"; stray tun*/wg* links are read from sysfs.
import AstalNetwork from "gi://AstalNetwork";
import GLib from "gi://GLib";
import NM from "gi://NM";
import { createBinding, createComputed } from "ags";
import { createPoll } from "ags/time";
import { execAsync } from "ags/process";

import {
  MESH,
  MESH_BADGE,
  OPENVPN,
  OPENVPN_BADGE,
  VPN,
  VPN_BADGE,
  WIREGUARD,
  WIREGUARD_BADGE,
} from "../glyphs";

export type TunnelKind = "mesh" | "openvpn" | "wireguard" | "vpn";

export interface Tunnel {
  kind: TunnelKind;
  /** Profile name, tailnet or interface — whatever identifies this tunnel. */
  name: string;
}

/** A tunnel discovered from a kernel link rather than from a NM profile. */
interface LinkTunnel extends Tunnel {
  iface: string;
}

const NET_DIR = "/sys/class/net";
const MESH_IFACE = "tailscale0";
const POLL_MS = 5000;

// Interfaces NetworkManager does not know about, keyed by the naming convention
// their tool uses. wg-quick names the link after the profile; openvpn takes the
// next free tun/tap.
const LINK_KINDS: Array<[RegExp, TunnelKind]> = [
  [/^wg[-\w]*$/, "wireguard"],
  [/^(tun|tap)\d+$/, "openvpn"],
];

export function tunnelGlyph(kind: TunnelKind): string {
  switch (kind) {
    case "mesh":
      return MESH;
    case "openvpn":
      return OPENVPN;
    case "wireguard":
      return WIREGUARD;
    default:
      return VPN;
  }
}

export function tunnelBadgeGlyph(kind: TunnelKind): string {
  switch (kind) {
    case "mesh":
      return MESH_BADGE;
    case "openvpn":
      return OPENVPN_BADGE;
    case "wireguard":
      return WIREGUARD_BADGE;
    default:
      return VPN_BADGE;
  }
}

/** Human name for the kind, used by the tooltip and the panel row. */
export function tunnelKindLabel(kind: TunnelKind): string {
  switch (kind) {
    case "mesh":
      return "Tailscale";
    case "openvpn":
      return "OpenVPN";
    case "wireguard":
      return "WireGuard";
    default:
      return "VPN";
  }
}

export function tunnelLabel(tunnel: Tunnel): string {
  const kind = tunnelKindLabel(tunnel.kind);
  return tunnel.name && tunnel.name !== kind ? `${kind}: ${tunnel.name}` : kind;
}

/**
 * Classify a NetworkManager tunnel.
 *
 * Native WireGuard profiles report a "wireguard" connection type with `vpn`
 * false; plugin-based VPNs report `vpn` true and name the plugin in the VPN
 * setting's service type, which is the only place OpenVPN is distinguishable
 * from any other plugin.
 */
function nmKind(active: NM.ActiveConnection): TunnelKind {
  if (active.get_connection_type() === "wireguard") return "wireguard";

  try {
    const service =
      active.get_connection()?.get_setting_vpn()?.get_service_type() ?? "";

    if (service.endsWith(".openvpn")) return "openvpn";
    if (service.endsWith(".wireguard")) return "wireguard";
  } catch {
    // Older NM typelibs do not expose the VPN setting on a remote connection.
  }

  return "vpn";
}

/**
 * The NetworkManager tunnels, plus the interfaces they carry.
 *
 * The interfaces are collected from these connections only, never from every
 * active connection: NetworkManager also tracks links it does not manage —
 * tailscale0 among them — and excluding those would drop the very tunnels the
 * poll exists to find.
 */
function nmTunnels(client: NM.Client): { tunnels: Tunnel[]; ifaces: Set<string> } {
  const tunnels: Tunnel[] = [];
  const ifaces = new Set<string>();

  for (const active of client.get_active_connections()) {
    const isTunnel =
      active.get_vpn() || active.get_connection_type() === "wireguard";

    if (!isTunnel || active.get_state() !== NM.ActiveConnectionState.ACTIVATED) {
      continue;
    }

    tunnels.push({ kind: nmKind(active), name: active.get_id() ?? "VPN" });

    for (const device of active.get_devices()) {
      const iface = device.get_iface();
      if (iface) ifaces.add(iface);
    }
  }

  return { tunnels, ifaces };
}

function listLinks(): string[] {
  try {
    const dir = GLib.Dir.open(NET_DIR, 0);
    const names: string[] = [];

    for (let name = dir.read_name(); name; name = dir.read_name()) {
      names.push(name);
    }

    dir.close();
    return names;
  } catch {
    return [];
  }
}

/**
 * Mesh state from the tailscale CLI.
 *
 * Only asked for when the interface exists, so hosts without tailscaled never
 * pay for the subprocess, and `--peers=false` keeps the response to the local
 * node. The CLI is taken from the session PATH rather than pinned by the bar's
 * wrapper: it talks to a local daemon whose version has to match, and on these
 * hosts both come from the same system closure. When it is missing the mesh is
 * reported as down rather than guessed at from the interface, which survives
 * `tailscale down`.
 */
async function meshTunnel(): Promise<LinkTunnel | null> {
  if (!GLib.file_test(`${NET_DIR}/${MESH_IFACE}`, GLib.FileTest.EXISTS)) {
    return null;
  }

  try {
    const status = JSON.parse(
      await execAsync(["tailscale", "status", "--json", "--peers=false"]),
    );

    if (status.BackendState !== "Running") return null;

    const name =
      status.CurrentTailnet?.Name || status.MagicDNSSuffix || "Tailscale";

    return { kind: "mesh", name, iface: MESH_IFACE };
  } catch {
    return null;
  }
}

function linkTunnels(): LinkTunnel[] {
  const tunnels: LinkTunnel[] = [];

  for (const iface of listLinks()) {
    const match = LINK_KINDS.find(([pattern]) => pattern.test(iface));
    if (match) tunnels.push({ kind: match[1], name: iface, iface });
  }

  return tunnels.sort((a, b) => a.iface.localeCompare(b.iface));
}

function tunnelKey(list: Tunnel[]): string {
  return list.map((tunnel) => `${tunnel.kind}\u0000${tunnel.name}`).join("\u0001");
}

/**
 * Poll body for the tunnels NetworkManager cannot see.
 *
 * The previous value is returned unchanged when nothing moved: createPoll
 * notifies on identity, so building a fresh array every tick would wake the
 * whole network status — and the panel rows built from it — every few seconds.
 */
async function readUnmanaged(prev: LinkTunnel[]): Promise<LinkTunnel[]> {
  const mesh = await meshTunnel();
  const next = mesh ? [mesh, ...linkTunnels()] : linkTunnels();

  return tunnelKey(next) === tunnelKey(prev) ? prev : next;
}

/**
 * Every tunnel currently up, NM-managed first.
 *
 * The NM half recomputes on the client's active-connection property; the poll
 * half is the only way to see a tunnel NM never learned about. A polled link
 * whose interface belongs to an active NM tunnel profile is dropped so a
 * NetworkManager WireGuard profile is not also counted as a stray wg link. It
 * lives at module scope because tunnel state is global and outlives any single
 * widget.
 */
function createTunnels() {
  const client = AstalNetwork.get_default().client;
  const active = createBinding(client, "activeConnections");
  const unmanaged = createPoll<LinkTunnel[]>([], POLL_MS, readUnmanaged);

  return createComputed([active, unmanaged], () => {
    const managed = nmTunnels(client);

    return [
      ...managed.tunnels,
      ...unmanaged
        .get()
        .filter((tunnel) => !managed.ifaces.has(tunnel.iface))
        .map(({ kind, name }) => ({ kind, name })),
    ];
  });
}

export const tunnels = createTunnels();
