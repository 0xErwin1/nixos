# Repository Guide for Coding Agents

## Purpose

This is a personal Nix flake for NixOS hosts and Home Manager profiles. Keep machine-specific configuration separate from shared modules, and treat the tracked `ai/` tree as the canonical source for the local AI coding harness.

## Hosts and Profiles

| Host | System | Role | Current flake outputs |
|---|---|---|---|
| `epsilon` | NixOS, x86_64 | ThinkPad; Hyprland/Wayland workstation | `nixosConfigurations.epsilon`, `homeConfigurations."iperez@epsilon"` |
| `zeta` | NixOS, x86_64 | ThinkPad X13; full-lite and thin/RDP use | `nixosConfigurations.zeta`, `homeConfigurations."iperez@zeta"`, `homeConfigurations."iperez@zeta-thin"` |
| `delta` | Arch Linux, x86_64 | Standalone Home Manager | `homeConfigurations."iperez@delta"` |
| `pi` | NixOS, aarch64 | Orange Pi 5 Plus; headless development host | `nixosConfigurations.pi`, `homeConfigurations."iperez@pi"` |

The two deploy-rs nodes refer to the same Pi:

- `pi-host-bootstrap`: LAN/bootstrap endpoint `10.42.0.2`
- `pi-host`: WireGuard/normal endpoint `10.0.0.2`

Each node activates `system` first and `home` second. See `docs/pi-operations.md` before changing Pi boot, networking, SSH, deployment, or secrets.

## Common Commands

Run repository commands from the repository root.

```bash
# Apply NixOS hosts
sudo nixos-rebuild switch --flake .#epsilon
sudo nixos-rebuild switch --flake .#zeta

# Apply standalone Home Manager on delta
home-manager switch --flake .#iperez@delta

# Evaluate repository checks without building
nix flake check --no-build

# Full check used for shared modules or AI harness changes without lock-file writes
nix flake check --no-build --no-write-lock-file
```

For the Pi, enter the flake environment with `direnv allow`, then use the documented deploy tasks:

```bash
# Normal deployment over WireGuard
devenv tasks run pi:deploy --mode single --show-output

# Bootstrap or recovery deployment over LAN
devenv tasks run pi:deploy-bootstrap --mode single --show-output

# Deploy one Pi profile over WireGuard
deploy .#pi-host.system --skip-checks
deploy .#pi-host.home --skip-checks
```

Before risky Pi changes, run the focused checks listed in `docs/pi-operations.md`; deployment tasks intentionally skip repository-wide checks.

## Repository Layout

- `flake.nix`: inputs, overlays, host/profile outputs, deploy-rs nodes, checks, and development shell.
- `hosts/<host>/`: host-specific NixOS configuration and hardware details.
- `hosts/globals/`: shared NixOS modules.
- `home-manager/<profile>/`: profile-specific Home Manager composition.
- `home-manager/global/`: shared Home Manager modules.
- `home-manager/headless/`: shared headless composition and services used by Pi.
- `pkgs/`: locally packaged software exposed through the overlay.
- `tests/`: flake-level functional assertions.
- `docs/pi-operations.md`: canonical Pi operations and recovery guide.
- `ai/`: canonical, tracked, secret-free AI harness assets.

Put a setting in a host/profile directory when it is machine- or role-specific. Put it in a shared module only when all importing profiles should inherit it. Review imports before broadening shared behavior.

## AI Harness

`home-manager/global/ai-harness.nix` connects canonical assets under `ai/` to Pi, OpenCode, Claude Code, Codex, and Grok Build.

- Static skills, agents, commands, prompts, and policy files are projected by Home Manager, generally as Nix store symlinks.
- Fully owned secret-bearing configs are rendered at activation from tracked placeholder templates.
- Agent-owned runtime configs are merged at activation so OAuth, trust, caches, and other runtime state are preserved.
- The shared MCP set includes `aws`, `context7`, `figma`, `penpot`, `dbflux`, `engram`, `obsidian`, and `atlas`, with per-agent adjustments.
- Reviews: 4R and Judgment Day are separate explicit opt-ins; this harness does not run the gentle-ai RDD review lifecycle.

Safe AI harness workflow:

1. Edit the canonical source in `ai/`, not projected files under `~/.config/opencode`, `~/.claude`, `~/.codex`, `~/.grok`, or `~/.pi`.
2. Update `home-manager/global/ai-harness.nix` only when projection, render, merge, or secret-contract wiring changes.
3. Keep tracked templates placeholder-only; never add rendered credentials.
4. Run `nix flake check --no-build --no-write-lock-file` for shared harness changes.
5. Read `ai/support/` when changing projection or secret behavior.

Do not copy or expand the large global agent policies in `ai/` into repository-local guidance.

## Secrets

Secrets are machine-local and external to Git:

- `~/.config/ai-harness/secrets/mcp.env`
- `~/.config/ai-harness/secrets/api.env`

Both files must exist and be mode `600`; `api.env` may be empty. Required variable names are documented in `ai/support/secrets-env-contract.md`. Never read, print, log, commit, or place secret values in Nix expressions, templates, tests, documentation, command arguments, or the Nix store. Do not bypass activation preflight checks.

WireGuard configuration also depends on external local material. Follow `docs/pi-operations.md` and never expose private keys.

## Verification and Safety

- Make the smallest coherent change and preserve existing patterns.
- Inspect relevant imports and outputs before editing shared modules.
- Run the most focused applicable check, then repository-wide checks for shared changes.
- Use `git diff --check` on edited files and inspect `git status` before reporting completion.
- Do not deploy or switch a host unless explicitly requested.
- Do not commit, amend, rebase, reset, or push unless explicitly requested.
- Preserve unrelated work; do not edit or revert files outside the requested scope.
- Never regenerate hardware configuration or lock files as a side effect of unrelated work.
