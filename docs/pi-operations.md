# Orange Pi Development Host Operations

This is the operator guide for `pi`, the Orange Pi 5 Plus used as a headless
development host. The machine runs aarch64 NixOS from NVMe through EDK2 and
systemd-boot, with a standalone Home Manager profile for `iperez`.

Run repository commands from `/home/iperez/.config/home-manager`. Commands are
labeled by where they run: **workstation**, **Pi**, or **WireGuard hub**.

## Daily Path

Enter the repository environment on the **workstation**:

```bash
direnv allow
```

Deploy both profiles through the local endpoint:

```bash
devenv tasks run pi:deploy --mode single --show-output
```

The `pi-host` node connects to `iperez@192.168.1.100` and activates profiles in
this order:

1. `system` runs as `root` through interactive sudo.
2. `home` runs as `iperez` with profile path
   `/home/iperez/.local/state/nix/profiles/home-manager`.

Deploy one profile only when recovery or a focused change requires it:

```bash
deploy .#pi-host.system --skip-checks
deploy .#pi-host.home --skip-checks
```

The system profile prompts for the `iperez` sudo password on the Pi. An SSH
password prompt is not expected because password authentication is disabled.

## Network Model

NetworkManager owns both physical interfaces through declarative profiles:

| Profile | Interface | IPv4 behavior |
|---|---|---|
| `pi-wifi` | `wifi0` | Static `192.168.1.100/24`, gateway and DNS `192.168.1.1` |
| `pi-ethernet` | `enP4p65s0` | DHCP |

The Wi-Fi profile retains UUID `4695ce6d-f84f-4354-bd4f-75c7dc65adae` so the
declarative profile replaces the existing runtime identity instead of creating
a second connection. Wi-Fi powersave remains disabled.

`wifi0` is a stable name assigned by a systemd link file that matches the USB
wifi adapter's permanent MAC address, so the interface keeps the same name and
profile on any USB port. If the adapter is ever replaced, update the MAC in
`hosts/pi/default.nix`.

`wg0` remains `10.0.0.2/24` for VPN-routed development traffic. The deploy-rs
transport does not use that address; deployment and local recovery use
`192.168.1.100`.

Verify the evaluated node without connecting to the Pi:

```bash
nix eval --raw .#deploy.nodes.pi-host.hostname
```

## Encrypted Secrets

`.sops.yaml` declares the administrator and Pi age recipients.
`secrets/pi.yaml` stores these encrypted values:

- `pi/wireguard-private-key`
- `pi/wifi-ssid`
- `pi/wifi-psk`

The encrypted YAML may enter the Nix store. Plaintext must not enter Git, Nix
expressions, derivations, command arguments, logs, or persistent temporary
files. On the Pi, `sops-nix` derives an age identity from
`/etc/ssh/ssh_host_ed25519_key` and writes root-owned runtime material under
`/run/secrets`.

`hosts/pi/secrets.nix` renders `/run/secrets/rendered/networkmanager.env` from
sops placeholders. `NetworkManager-ensure-profiles.service` waits for
`sops-install-secrets.service` before reading that environment file. WireGuard
reads `/run/secrets/pi/wireguard-private-key` directly and has the same ordering
constraint. Secret changes restart the affected units.

### Edit secrets

Use the external administrator age key on the **workstation** and edit through
SOPS. Do not create a decrypted copy:

```bash
SOPS_AGE_KEY_FILE="$HOME/.config/sops/age/keys.txt" sops secrets/pi.yaml
sops filestatus secrets/pi.yaml
```

Before accepting an edit, confirm that `sops filestatus` reports
`{"encrypted":true}` and inspect only key names or encrypted metadata. Never
print or pipe decrypted values for validation.

### Change recipients

Update `.sops.yaml` with public recipients only, then rewrap the encrypted data
keys using the administrator identity:

```bash
SOPS_AGE_KEY_FILE="$HOME/.config/sops/age/keys.txt" sops updatekeys secrets/pi.yaml
sops filestatus secrets/pi.yaml
```

Do not remove the currently deployed Pi recipient until a replacement identity
has been installed and validated. Rewrapping recipients does not rotate the
secret values.

### Rotate the WireGuard key

Edit only `pi/wireguard-private-key` through SOPS, derive its public key inside
the protected editor workflow, and replace the Pi peer on the hub. The hub must
have one active peer owning `10.0.0.2/32`; duplicate peers with that route are
not a safe overlap strategy.

Keep local SSH access at `192.168.1.100` throughout the rotation. After updating
the hub and encrypted file, deploy the system profile, confirm a recent
handshake, then deploy Home Manager if it also changed.

## Migration Procedure

The first activation changes network ownership and secret provisioning. Keep
physical console access available even though `192.168.1.100` is already the
working runtime address.

1. Confirm `ssh -o BatchMode=yes iperez@192.168.1.100 true`.
2. Confirm the Pi still has `/etc/ssh/ssh_host_ed25519_key`; inspect metadata,
   not private-key contents.
3. Confirm `sops filestatus secrets/pi.yaml` reports encrypted data and
   `.sops.yaml` contains both public recipients.
4. Run the focused checks in this guide.
5. Deploy only the system profile with `deploy .#pi-host.system --skip-checks`.
6. Reconnect to `192.168.1.100` and validate NetworkManager, sops, WireGuard,
   SSH, routes, and failed units.
7. Deploy the Home Manager profile with
   `deploy .#pi-host.home --skip-checks`.

Do not remove access to the prior bootable NixOS generation until the new
network profiles and secret-backed services survive a reboot performed in a
separate, explicitly approved maintenance window.

## Verification

Run focused repository checks on the **workstation** before any deployment:

```bash
nix build .#checks.x86_64-linux.pi-outputs --no-link --no-write-lock-file
nix build .#checks.x86_64-linux.deploy-schema --no-link --no-write-lock-file
nix build .#checks.x86_64-linux.deploy-activate --no-link --no-write-lock-file
bash -n scripts/pi/*
```

Run the full evaluation when shared modules or AI harness assets change:

```bash
nix flake check --no-build --no-write-lock-file
```

After the approved system activation, validate on the **Pi** without reading
secret values:

```bash
hostname
nmcli connection show
ip -brief address show wifi0 enP4p65s0 wg0
ip route
stat -c '%U %G %a %n' /run/secrets/pi/wireguard-private-key \
  /run/secrets/rendered/networkmanager.env
systemctl status sops-install-secrets NetworkManager-ensure-profiles wg-quick-wg0 --no-pager
systemctl --failed
sudo wg show wg0
```

From the **workstation**:

```bash
ssh -o BatchMode=yes iperez@192.168.1.100 hostname
nix eval --raw .#deploy.nodes.pi-host.hostname
```

The Pi task uses deploy-rs `--skip-checks` because repository-wide checks also
cover unrelated x86_64 outputs. This does not replace the focused checks above.
Do not add node-wide `sshOpts = [ "-tt" ]`; forcing a pseudo-terminal corrupts
deploy-rs Nix daemon transport. `interactiveSudo = true` allocates a terminal
only for privileged activation.

## Rollback

The rollback boundary is the NixOS system generation plus the three encrypted
secret entries. Home Manager is independent and should be rolled back only if
its activation changed.

If the new system remains reachable at `192.168.1.100`, inspect generations and
failed units before changing state:

```bash
readlink -f /nix/var/nix/profiles/system
sudo nix-env --profile /nix/var/nix/profiles/system --list-generations
systemctl --failed
journalctl -b -p warning --no-pager
```

Use the prior NixOS generation from the Pi console or local SSH when required:

```bash
sudo nixos-rebuild switch --rollback
```

If a WireGuard rotation fails, restore both sides of the pair: the previous
encrypted secret revision and the previous root-owned hub configuration. Apply
the hub peer first, activate the matching Pi system generation through local
SSH, and then validate the handshake. Do not garbage-collect until local SSH,
NetworkManager, WireGuard, and both profile generations are healthy.

## SSH And AI Credentials

SSH key authentication is declared in `hosts/pi/default.nix`. Root SSH,
password authentication, and keyboard-interactive authentication are disabled;
administration connects as `iperez` and elevates with sudo.

AI harness credentials remain separate from sops-managed network secrets:

| Path | Owner and mode |
|---|---|
| `/home/iperez/.config/ai-harness/secrets/` | `iperez`, `0700` |
| `/home/iperez/.config/ai-harness/secrets/mcp.env` | `iperez`, `0600` |
| `/home/iperez/.config/ai-harness/secrets/api.env` | `iperez`, `0600` |

Home Manager reads these files during activation and preserves runtime OAuth,
trust, and cache state. Never place their values in the encrypted Pi network
file or in Nix.

## Development Services

The NixOS firewall trusts `wg0`, so authenticated WireGuard peers can reach
services listening on the Pi. A process bound only to `127.0.0.1` remains local.
Treat hub peer enrollment as the access-control boundary and keep application
authentication enabled for sensitive services.

Home Manager owns the lingering `herdr-server.service` and loopback-only
`chromium-cdp.service`. Connect Herdr through local SSH:

```bash
herdr --remote ssh://iperez@192.168.1.100
```

Chromium DevTools has no authentication and must remain on `127.0.0.1:9222`.
Reach it only through an SSH tunnel:

```bash
ssh -N -L 9222:127.0.0.1:9222 iperez@192.168.1.100
curl --fail http://127.0.0.1:9222/json/version
```

## File Map

| Path | Role |
|---|---|
| `flake.nix` | Pins inputs, imports sops only for Pi, and defines the single deploy node and ordered profiles. |
| `flake.lock` | Pins the exact sops-nix and existing dependency revisions. |
| `.sops.yaml` | Public age recipient policy for encrypted Pi secrets. |
| `secrets/pi.yaml` | Encrypted Pi network and WireGuard values. |
| `hosts/pi/default.nix` | Host identity, NetworkManager profiles, SSH policy, users, and module imports. |
| `hosts/pi/secrets.nix` | sops identity, root-only secrets, runtime template, and service ordering. |
| `hosts/pi/wireguard.nix` | `wg0`, unchanged peer behavior, sops-backed key path, and firewall trust. |
| `scripts/pi/deploy` | Deploys the single ordered deploy-rs node. |
| `tests/pi-outputs.nix` | Evaluated assertions for Pi outputs, networking, secrets, WireGuard, and deployment. |

The hardware path remains NVMe root plus a vfat EFI system partition. EDK2
starts systemd-boot, and NixOS manages system generations. This repository does
not contain the firmware installation procedure.
