# Orange Pi Development Host Operations

This is the canonical operator guide for `pi`, the Orange Pi 5 Plus used as a
headless development host. The machine runs aarch64 NixOS from NVMe through
EDK2 and systemd-boot, with a standalone Home Manager profile for `iperez`.

Commands are labeled by where they run: **workstation**, **Pi (LAN)**,
**Pi (VPN)**, or **hub**. Run repository commands from the repository root,
`/home/iperez/.config/home-manager`, unless stated otherwise.

## Daily Quick Path

### Enter or refresh the workstation environment

The repository `.envrc` contains `use flake`. On the **workstation**:

```bash
cd /home/iperez/.config/home-manager
direnv allow
```

After changing `.envrc` or the development shell:

```bash
direnv reload
```

The flake shell provides `deploy`, `devenv`, `secretspec`, `wg`, `ssh`, `nix`,
`home-manager`, `git`, `nil`, and `nixfmt`. `shell.nix` is the non-flake
fallback and contains the core deployment tools.

List the available tasks:

```bash
devenv tasks list
```

### Deploy

Use LAN while bootstrapping or recovering:

```bash
devenv tasks run pi:deploy-bootstrap --mode single --show-output
```

Use the VPN for normal operation after WireGuard has been validated:

```bash
devenv tasks run pi:deploy --mode single --show-output
```

Target one deploy-rs profile when only that layer needs activation:

```bash
# Workstation: system through VPN
deploy .#pi-host.system --skip-checks

# Workstation: Home Manager through VPN
deploy .#pi-host.home --skip-checks

# Workstation: system through LAN
deploy .#pi-host-bootstrap.system --skip-checks

# Workstation: Home Manager through LAN
deploy .#pi-host-bootstrap.home --skip-checks
```

The system profile prompts for the `iperez` sudo password. This is a sudo
prompt on the Pi, not an SSH password prompt.

## Address And Deployment Map

| Name | Address or endpoint | Purpose |
|---|---|---|
| Pi LAN | `10.42.0.2/24` on `enP4p65s0` | Bootstrap and recovery path |
| LAN gateway | `10.42.0.1` | Pi default gateway |
| Pi WireGuard | `10.0.0.2/24` on `wg0` | Normal remote administration |
| WireGuard hub | `142.44.162.92:51820` | External VPN hub |
| `pi-host-bootstrap` | deploy-rs node at `10.42.0.2` | LAN deployment |
| `pi-host` | deploy-rs node at `10.0.0.2` | VPN deployment |

Both deploy-rs nodes describe the same machine and the same two profiles. The
different node names select only the transport endpoint.

## Deployment Model

Each node activates profiles in this order:

1. `system` runs as `root`, using interactive sudo and the NixOS configuration
   `nixosConfigurations.pi`.
2. `home` runs as `iperez`, using the standalone Home Manager configuration
   `homeConfigurations."iperez@pi"` and profile path
   `/home/iperez/.local/state/nix/profiles/home-manager`.

The explicit Home Manager user and profile path are required. Without them,
remote activation can resolve the home directory or profile as root's.

Both nodes set `remoteBuild`, `autoRollback`, and `magicRollback`. Builds occur
on the aarch64 target. Failed activation can roll back automatically, and magic
rollback requires deploy-rs to reconnect and confirm that the host remained
reachable.

The Pi task scripts call deploy-rs with `--skip-checks`. Repository-wide checks
include unrelated x86_64 and global AI harness work; running all of them on
every Pi deployment would make routine operations depend on unrelated outputs.
This does not make risky edits check-free. Before changes to boot, networking,
SSH, profile activation, or secrets, run the focused Pi/deploy checks:

```bash
# Workstation
nix build .#checks.x86_64-linux.pi-outputs --no-link --no-write-lock-file
nix build .#checks.x86_64-linux.deploy-schema --no-link --no-write-lock-file
nix build .#checks.x86_64-linux.deploy-activate --no-link --no-write-lock-file
bash -n scripts/pi/*
```

Run the full check when a change affects shared modules or AI harness assets:

```bash
nix flake check --no-build --no-write-lock-file
```

Do not add a node-wide `sshOpts = [ "-tt" ]`. deploy-rs transports Nix daemon
data over SSH standard input/output, and a forced pseudo-terminal corrupts or
hangs that transport. `interactiveSudo = true` allocates a terminal only where
the privileged activation needs one.

## SSH Authentication

`iperez` key authentication is declared in `hosts/pi/default.nix`; unattended
SSH checks therefore work with `BatchMode`:

```bash
# Workstation, LAN
ssh -o BatchMode=yes iperez@10.42.0.2 true

# Workstation, VPN
ssh -o BatchMode=yes iperez@10.0.0.2 true
```

The SSH service disables password and keyboard-interactive authentication, and
root SSH login is disabled. Administration connects as `iperez` and elevates
with sudo. A password prompt during a system deployment is the expected sudo
prompt; an SSH password prompt indicates that key authentication is not
working.

## AI Harness Credentials

Home Manager requires these machine-local files on the Pi before activation:

| File | Owner and mode | Current purpose |
|---|---|---|
| `/home/iperez/.config/ai-harness/secrets/mcp.env` | `iperez`, `0600` | MCP credentials |
| `/home/iperez/.config/ai-harness/secrets/api.env` | `iperez`, `0600` | API credentials; may currently be empty |
| `/home/iperez/.config/ai-harness/secrets/` | `iperez`, `0700` | Private credential directory |

The current render requires non-empty values for at least `ATLAS_TOKEN`,
`CONTEXT7_API_KEY`, and `PENPOT_API_KEY`. Values must never be committed,
printed, logged, included in Nix expressions, or otherwise placed in the Nix
store.

For initial transfer from a trusted **workstation**, use the LAN path. The
following assumes the trusted workstation already has both files at the same
canonical paths; it does not display their contents:

```bash
ssh iperez@10.42.0.2 'install -d -m 0700 /home/iperez/.config/ai-harness/secrets'
scp ~/.config/ai-harness/secrets/mcp.env \
  ~/.config/ai-harness/secrets/api.env \
  iperez@10.42.0.2:/home/iperez/.config/ai-harness/secrets/
ssh iperez@10.42.0.2 \
  'chmod 0700 /home/iperez/.config/ai-harness/secrets && chmod 0600 /home/iperez/.config/ai-harness/secrets/*.env'
```

Verify metadata without reading values:

```bash
# Pi (LAN or VPN)
stat -c '%U %a %n' \
  ~/.config/ai-harness/secrets \
  ~/.config/ai-harness/secrets/mcp.env \
  ~/.config/ai-harness/secrets/api.env
```

`home-manager/global/ai-harness.nix` captures the complete canonical `ai/`
tree with `builtins.path`, so the sources needed during remote activation are
part of the Home Manager closure. It projects static resources and renders or
merges credential-bearing configuration for OpenCode, Claude Code, Codex, and
Pi. Credential values are read only during activation from the two external env
files; templates in `ai/` contain placeholders, not values.

## WireGuard Enrollment

### 1. Initialize SecretSpec

On the **workstation**, initialize the provider once. A keyring-backed provider
is recommended so the private key does not live in the repository:

```bash
devenv tasks run pi:secrets-init --mode single --show-output
```

This runs `secretspec config init`; follow its provider prompts. The repository
keeps `devenv.yaml` integration disabled because the scripts invoke SecretSpec
explicitly.

### 2. Create and validate the Pi key once

```bash
# Workstation
devenv tasks run pi:key-create --mode single --show-output
```

`secretspec.toml` declares `PI_WIREGUARD_PRIVATE_KEY` as a generated `wg
genkey` command secret with `as_path = true`. The task validates the material
with `wg pubkey` and removes SecretSpec's temporary materialized file. Run this
for initial creation, not as a routine deployment step.

### 3. Obtain only the public key

```bash
# Workstation
devenv tasks run pi:public-key --mode single
```

The command writes only the derived public key to standard output. It does not
print the private key.

### 4. Enroll the peer on the external hub

Edit `/etc/wireguard/wg0.conf` on the **hub**. Replace the old Pi peer block
rather than adding a second active peer for the same address:

```ini
[Peer]
PublicKey = <PI_PUBLIC_KEY>
AllowedIPs = 10.0.0.2/32
```

Validate and apply the file without tearing down the hub interface:

```bash
# Hub
sudo wg-quick strip wg0 >/dev/null
sudo bash -c 'wg syncconf wg0 <(wg-quick strip wg0)'
sudo wg show wg0
```

### 5. Inject the key over LAN

The system/helper must already have been deployed through LAN. Then, on the
**workstation**:

```bash
devenv tasks run pi:key-inject --mode single --show-output
```

The task resolves the private key to a temporary local path, validates it, and
sends it over SSH standard input to the fixed sudo helper at `10.42.0.2`. The
private key is not passed as an argument.

### 6. Start WireGuard and deploy through it

After the hub peer is active:

```bash
# Workstation: reinject, restart wg0 over LAN, then deploy through VPN
devenv tasks run pi:wireguard-deploy --mode single --show-output
```

`pi:wireguard-deploy` runs `pi:key-inject`, restarts `wg-quick-wg0` through the
LAN endpoint, and then runs the normal `pi-host` deployment through
`10.0.0.2`. Validate the tunnel and VPN SSH before using `pi:deploy` for normal
operations:

```bash
# Workstation
ping -c 3 10.0.0.2
ssh -o BatchMode=yes iperez@10.0.0.2 true
devenv tasks run pi:deploy --mode single --show-output
```

## Target Key Contract

The target private key contract is deliberately narrow:

| Property | Contract |
|---|---|
| Path | `/var/lib/wireguard/pi-host-private.key` |
| Ownership | `root:root` |
| Mode | `0600` (`/var/lib/wireguard` is `0700`) |
| Installer | `/run/current-system/sw/bin/pi-wireguard-key-install` |
| Arguments | None; arguments are rejected |
| Input | Exactly one private key on standard input |
| Validation | `wg pubkey` must accept the candidate |
| Replacement | Same-directory temporary file, sync, atomic rename |
| Failure | Invalid/oversized input is rejected and the old key remains |

The `wg-quick-wg0` unit has a `ConditionPathExists` check for this path. A fresh
system can therefore activate before enrollment without leaving a failed
WireGuard unit.

## Development Service Ports

The NixOS firewall trusts `wg0`. Any authenticated peer routed through the
WireGuard hub can therefore reach any TCP or UDP port exposed by the Pi, while
the same ports remain subject to the firewall on the LAN and other interfaces.
This supports project-managed databases, backends, frontend development
servers, and container-published ports without adding a NixOS firewall rule for
every project.

A service must listen on `0.0.0.0`, `::`, or `10.0.0.2` to be reachable from
another WireGuard peer. A process bound only to `127.0.0.1` remains local. For
example:

```bash
# Pi: inspect listening addresses and ports
ss -lntup

# Workstation: verify an HTTP development server over WireGuard
curl --fail http://10.0.0.2:8080/
```

For containers, publish the port through Podman and prefer binding it to the
WireGuard address when the service should not also listen on LAN:

```bash
# Pi: VPN-only publication example
podman run --rm -p 10.0.0.2:8080:8080 example/image:tag
```

Trusting `wg0` means every peer admitted to this WireGuard network can attempt
to connect to every service listening on the Pi. Treat hub peer enrollment as
the access-control boundary, remove obsolete peers promptly, and keep
application authentication enabled for sensitive databases and admin APIs.

## Headless User Services

Home Manager owns two long-running user services on the Pi:

| Unit | Purpose | Resource policy |
|---|---|---|
| `herdr-server.service` | Headless Herdr server hosting the agent panes | Default weight; not slice-pinned, its panes are interactive |
| `chromium-cdp.service` | Headless Chromium exposing a DevTools Protocol endpoint | `background.slice` |

`users.users.iperez.linger = true` in `hosts/pi/default.nix` is what keeps the
`iperez` systemd user manager running without a login session. Without it both
units would only exist while an SSH session was open and would die on logout.

```bash
# Pi: confirm lingering and unit state
loginctl show-user iperez --property=Linger
systemctl --user status herdr-server chromium-cdp
```

### Herdr

The Pi runs `herdr server`; clients attach to it over SSH. No tmux and no
persistent session on the Pi are involved:

```bash
# Workstation, VPN
herdr --remote ssh://iperez@10.0.0.2

# Workstation, LAN
herdr --remote ssh://iperez@10.42.0.2
```

The unit's `ExecStop` is `herdr server stop`, which shuts the server down
through its API socket. `systemctl --user restart herdr-server` therefore
terminates the running agent panes; restart it only when that is acceptable.

### Chromium DevTools Protocol

`chromium-cdp.service` listens on `127.0.0.1:9222` only. The DevTools Protocol
has no authentication: whoever reaches that port gets arbitrary code execution
and full access to the browser profile. The endpoint must never be bound to
`0.0.0.0` or to the WireGuard address, and it must never be published through
the firewall, even though `wg0` is trusted.

Remote access is an SSH tunnel, which keeps authentication on SSH:

```bash
# Workstation: forward the endpoint, then drive it locally
ssh -N -L 9222:127.0.0.1:9222 iperez@10.0.0.2

# Workstation, in another shell
curl --fail http://127.0.0.1:9222/json/version
```

The browser profile lives at `/home/iperez/.local/state/chromium-cdp` and is
runtime-owned state, not Home Manager state.

### X11 forwarding

`services.openssh.settings.X11Forwarding = true` allows a graphical program run
on the Pi to display on the workstation. The Pi keeps `services.xserver.enable
= false`: forwarding needs `xauth` on the server, not a local X server, and
NixOS wires `XAuthLocation` into `sshd_config` automatically when forwarding is
enabled. The workstation supplies the X display:

```bash
# Workstation, with a running X or XWayland display
ssh -X iperez@10.0.0.2 xterm
```

## Key Rotation

Never rotate only through the tunnel whose key is being replaced. Keep the LAN
path at `10.42.0.2` reachable for the entire operation.

WireGuard cannot provide useful simultaneous hub peers with the same
`AllowedIPs = 10.0.0.2/32`; one peer owns that route. The safe overlap is a
staged overlap: retain the working old hub peer while preparing the new key and
retain a root-only backup of the old hub configuration for immediate rollback.
Do not leave duplicate active Pi peers after cutover.

1. Confirm LAN SSH and save the current hub configuration with root-only
   permissions.
2. Rotate `PI_WIREGUARD_PRIVATE_KEY` in the configured SecretSpec provider by
   the provider's supported rotation method. Provider mutation is intentionally
   not scripted in this repository.
3. Run `pi:key-create` to validate the newly resolved value, then
   `pi:public-key`; do not print or capture the private value.
4. Prepare the replacement hub peer block, but leave the old peer active until
   the cutover window.
5. Replace the hub peer and apply it with `wg syncconf`.
6. Immediately run `pi:key-inject` over LAN and restart `wg-quick-wg0` over
   LAN.
7. Validate a recent handshake and SSH through `10.0.0.2`.
8. If validation fails, restore the old SecretSpec value and old hub
   configuration, reinject over LAN, and restart `wg-quick-wg0`.
9. Remove rotation backups only after VPN and deployment validation succeeds.

The repository cannot prescribe the SecretSpec provider's rotate/restore
command because provider selection occurs interactively in `pi:secrets-init`
and is not stored here.

## Bootstrap Or Reinstall

This procedure starts from a reachable NixOS installation on the Pi with
`iperez` SSH and sudo access. It adopts the existing NVMe/EDK2/systemd-boot boot
chain; it is not an installer image procedure.

1. Connect the direct LAN and confirm `ssh iperez@10.42.0.2`.
2. On the workstation, enter the flake environment with `direnv allow`.
3. Transfer both AI harness env files over LAN and set directory mode `0700`
   and file mode `0600` before any Home Manager activation.
4. Deploy NixOS and Home Manager in order through LAN:

   ```bash
   devenv tasks run pi:deploy-bootstrap --mode single --show-output
   ```

5. If the first activation times out while changing `dbus-daemon` to
   `dbus-broker`, reboot cleanly over LAN and rerun the deployment:

   ```bash
   ssh -tt iperez@10.42.0.2 sudo systemctl reboot
   ```

6. If recovery requires separate activation, deploy the system first, reboot
   if needed, and then deploy Home Manager:

   ```bash
   deploy .#pi-host-bootstrap.system --skip-checks
   deploy .#pi-host-bootstrap.home --skip-checks
   ```

7. Initialize or restore SecretSpec on the workstation, enroll the public key
   on the hub, then run `pi:key-inject` followed by `pi:wireguard-deploy`.
8. Validate both LAN and VPN SSH. Use `pi:deploy` only after VPN validation.

## Validation

### Pi state

Run on the **Pi**, reached over LAN or VPN:

```bash
hostname
getent passwd iperez | cut -d: -f7
nixos-version
readlink -f /nix/var/nix/profiles/system
readlink -f ~/.local/state/nix/profiles/home-manager
podman info
systemctl --failed
```

Expected identity is hostname `pi`, login shell ending in `zsh`, an aarch64
NixOS system, populated system and standalone Home Manager profiles, working
Podman, and no failed units.

Validate AI harness projections and tools without opening secret files:

```bash
# Pi (LAN or VPN)
test -e ~/.config/opencode/AGENTS.md
test -e ~/.claude/CLAUDE.md
test -e ~/.codex/AGENTS.md
test -e ~/.pi/agent/AGENTS.md
command -v pi opencode claude codex engram
stat -c '%U %a %n' ~/.config/ai-harness/secrets ~/.config/ai-harness/secrets/*.env
```

CodeGraph is intentionally not part of the Pi profile; see Troubleshooting.

### WireGuard and access

```bash
# Pi (LAN or VPN)
sudo wg show wg0
ip -brief address show wg0
systemctl status wg-quick-wg0 --no-pager
```

```bash
# Workstation
ssh -o BatchMode=yes iperez@10.42.0.2 hostname
ssh -o BatchMode=yes iperez@10.0.0.2 hostname
```

Validate deploy-rs resolution without changing the target:

```bash
# Workstation
nix eval --json .#deploy.nodes.pi-host.hostname
nix eval --json .#deploy.nodes.pi-host-bootstrap.hostname
nix build .#checks.x86_64-linux.deploy-schema --no-link --no-write-lock-file
```

## Troubleshooting

| Symptom | Cause and action |
|---|---|
| Sudo prompt or useful output is hidden behind the devenv TUI | Run `DEVENV_TUI=false devenv tasks run <task> --mode single --show-output`. Both flake and fallback shells already set `DEVENV_TUI=false`, but the explicit prefix is useful outside them. |
| deploy-rs hangs during remote build/copy | Ensure no global `sshOpts = [ "-tt" ]` was added. A forced TTY breaks remote nix-daemon transport. Keep TTY allocation limited to interactive sudo. |
| Home Manager tries to use `/root` or a root profile | Keep `profiles.home.user = "iperez"` and `profiles.home.profilePath = "/home/iperez/.local/state/nix/profiles/home-manager"` on both deploy nodes. Deploy system first, then retry the home profile. |
| Home Manager reports a missing AI harness env file | Create both canonical files before activation and apply directory `0700`/file `0600` permissions. Do not bypass the preflight. |
| AI render reports a missing variable | Add the named non-empty variable to the appropriate local env file. Current templates require `ATLAS_TOKEN`, `CONTEXT7_API_KEY`, and `PENPOT_API_KEY`. Never put the value in Nix or Git. |
| Remote Home Manager activation cannot find an AI source template | `home-manager/global/ai-harness.nix` must keep the complete `ai/` tree in a `builtins.path` closure. Referencing only individual projections previously omitted activation-time templates from the remote closure. |
| First activation times out reloading D-Bus | The initial `dbus-daemon` to `dbus-broker` transition can inhibit or time out activation. Reboot cleanly through LAN, reconnect, and rerun the LAN deployment. |
| VPN succeeds but interactive SSH is slow | The current hub route is operational but has observed elevated latency. Compare LAN and VPN `ping`, inspect latest handshakes, and use LAN for recovery; tune the hub route separately. |
| Deployment disconnected or rolled back | Check the current system and Home Manager profile links and list generations before retrying. Auto/magic rollback may have restored the prior generation. Do not run garbage collection while diagnosing, because it can remove a generation needed for recovery. |

Profile inspection on the **Pi**:

```bash
readlink -f /nix/var/nix/profiles/system
sudo nix-env --profile /nix/var/nix/profiles/system --list-generations
readlink -f ~/.local/state/nix/profiles/home-manager
home-manager generations
journalctl -b -p warning --no-pager
```

If a failed system switch left the machine bootable, inspect generations first;
then use NixOS's rollback path if required:

```bash
# Pi (LAN), only after inspecting generations
sudo nixos-rebuild switch --rollback
```

Prefer LAN for rollback and subsequent redeployment. Do not garbage-collect
until both system and Home Manager are confirmed healthy.

## Recovery Checklist

- [ ] Keep or restore physical/LAN reachability to `10.42.0.2`.
- [ ] Confirm key-based `iperez` SSH before changing profiles or VPN state.
- [ ] Inspect current system and Home Manager profile links and generations.
- [ ] Check `systemctl --failed` and the current boot journal.
- [ ] Verify both AI harness env files exist with safe ownership and modes.
- [ ] Restore/deploy the system profile through `pi-host-bootstrap` first.
- [ ] Reboot cleanly if activation is blocked by the initial D-Bus transition.
- [ ] Activate the standalone Home Manager profile only after the system is sound.
- [ ] Restore the hub peer and inject the private key only through LAN.
- [ ] Validate WireGuard handshake and VPN SSH before returning to `pi-host`.
- [ ] Keep old generations and key/hub backups until end-to-end validation passes.

## Security Checklist

- [ ] SSH key authentication works with `BatchMode=yes` on required endpoints.
- [ ] Root SSH, password SSH, and keyboard-interactive SSH remain disabled.
- [ ] Administrative deployment connects as `iperez` and elevates with sudo.
- [ ] AI credential directory is `0700`; credential files are owned by `iperez`
      and mode `0600`.
- [ ] No credential value, private key, password hash, or rendered agent config is
      in Git, logs, command arguments, or the Nix store.
- [ ] `/var/lib/wireguard` is root-only and the Pi key is `root:root` `0600`.
- [ ] The WireGuard installer remains fixed, argument-free, stdin-only, and
      restricted by the exact sudo rule.
- [ ] The Chromium DevTools endpoint listens only on `127.0.0.1:9222`, and remote
      use goes through an SSH tunnel.
- [ ] The hub has one active Pi peer owning `10.0.0.2/32`.
- [ ] LAN recovery is retained before boot, SSH, deploy, or WireGuard changes.
- [ ] Focused checks pass before risky Pi edits.

## Architecture And File Map

| Path | Operational role |
|---|---|
| `flake.nix` | Defines aarch64 packages, `nixosConfigurations.pi`, `homeConfigurations."iperez@pi"`, both deploy-rs nodes/profiles, focused checks, and the flake development shell. |
| `flake.lock` | Pins inputs, including deploy-rs and Pi harness dependencies; unrelated local changes must be preserved. |
| `hosts/pi/default.nix` | NixOS host identity, static LAN, gateway/DNS, SSH policy (including X11 forwarding) and authorized key, `iperez` with lingering enabled, Zsh, boot loader, timezone, and module imports. |
| `hosts/pi/hardware-configuration.nix` | NVMe initrd support, ext4 root, vfat ESP, and aarch64 platform declaration. Regenerate/review if the disk layout changes. |
| `hosts/pi/virtualisation.nix` | Enables Podman and keeps libvirtd disabled. |
| `hosts/pi/wireguard.nix` | Defines the fixed atomic key installer, exact sudo permission, `wg0`, hub peer, and key-file systemd condition. |
| `home-manager/pi/default.nix` | Standalone `iperez` Home Manager identity, state version, editor, and headless import. |
| `home-manager/headless/default.nix` | Curated non-GUI composition: shell, Git, tmux, direnv, Herdr, Neovim, AI tools, utilities, CPU slices, and the headless user services. |
| `home-manager/headless/herdr-server.nix` | Declares `herdr-server.service`, the lingering Herdr headless server that `herdr --remote` attaches to. |
| `home-manager/headless/browserless.nix` | Declares `chromium-cdp.service`, headless Chromium with a loopback-only DevTools Protocol endpoint on `127.0.0.1:9222`. |
| `home-manager/global/ai-headless.nix` | Enables Pi, OpenCode, Claude Code, and Codex packages plus upstream Pi harness assets. |
| `home-manager/global/ai-harness.nix` | Captures the canonical `ai/` closure, projects static resources, checks external env files, and renders/merges runtime credential configs. |
| `home-manager/global/headless-utilities.nix` | Development CLI and language tooling, including Go, Python/uv, Node/pnpm, AWS CLI, GitLab CLI, `kalker`, and `nh`. |
| `home-manager/global/headless-cpu-slices.nix` | Defines user `build.slice` and `background.slice` resource policies. |
| `ai/` | Canonical tracked, secret-free agent assets and credential placeholders. |
| `ai/support/secrets-env-contract.md` | Canonical AI credential file and variable-name contract. |
| `devenv.nix` | Declares Pi tasks and task-time packages. |
| `devenv.yaml` | Keeps automatic SecretSpec integration disabled; scripts control when secrets are resolved. |
| `secretspec.toml` | Declares the generated WireGuard private-key contract and `pi` profile. |
| `.envrc` | Loads the flake environment through direnv. |
| `shell.nix` | Fallback development shell with deployment tools and TUI disabled. |
| `scripts/pi/secrets-init` | Runs one-time SecretSpec provider initialization. |
| `scripts/pi/key-create` | Resolves/generates and validates the private key without printing it, then cleans the materialized file. |
| `scripts/pi/public-key` | Derives and prints only the public key, then cleans the materialized private-key file. |
| `scripts/pi/key-inject` | Validates and streams the private key over LAN to the fixed root installer. |
| `scripts/pi/deploy-bootstrap` | Deploys both ordered profiles through `pi-host-bootstrap` with focused checks skipped. |
| `scripts/pi/deploy` | Deploys both ordered profiles through `pi-host` with focused checks skipped. |
| `scripts/pi/wireguard-deploy` | Injects over LAN, restarts Pi WireGuard over LAN, then deploys through VPN. |
| `tests/pi-outputs.nix` | Focused assertions for Pi system, standalone Home Manager, networking, boot, SSH, tools, and headless exclusions. |
| `tests/pi-harness-wiring.nix` | Checks Pi harness package/resource wiring and separation from runtime-owned state. |

The hardware path is NVMe root plus a vfat EFI system partition. EDK2 starts
systemd-boot; NixOS manages system generations. This repository adopts that
working boot chain and does not contain the firmware installation procedure.
