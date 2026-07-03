# NixOS & Home Manager Configuration

Personal dotfiles managed with Nix flakes.

## Hosts

| Host | OS | Description |
|------|-----|-------------|
| `epsilon` | NixOS | ThinkPad - Hyprland (Wayland) |
| `zeta` | NixOS | ThinkPad x13 - Full-lite + thin (RDP) |
| `delta` | Arch Linux | Standalone Home Manager |

## Usage

**NixOS (epsilon):**
```bash
sudo nixos-rebuild switch --flake .#epsilon
```

**NixOS (zeta):**
```bash
sudo nixos-rebuild switch --flake .#zeta
```

**Home Manager standalone (delta):**
```bash
home-manager switch --flake .#iperez@delta
```

**Check configuration:**
```bash
nix flake check --no-build
```

## Structure

```
.
├── flake.nix
├── ai/                   # Canonical AI agent assets (skills, agents, commands, MCP templates)
├── hosts/
│   ├── epsilon/          # NixOS host (ThinkPad)
│   │   ├── default.nix
│   │   ├── hardware-configuration.nix
│   │   ├── packages.nix
│   │   ├── virtualisation.nix
│   │   ├── wireguard.nix
│   │   └── wireguard-local.nix
│   └── globals/          # Shared NixOS modules
│       ├── default.nix
│       └── gaming.nix
│
└── home-manager/
    ├── epsilon/          # HM profile for NixOS
    ├── delta/            # HM profile for Arch
    └── global/           # Shared HM modules
        ├── window-managers/
        │   ├── hyprland/     # Wayland (active)
        │   ├── xmonad/       # X11
        │   ├── qtile/        # X11
        │   ├── bspwm/        # X11
        │   └── leftwm/       # X11
        ├── wayland/
        │   └── eww/
        ├── zed/
        ├── zsh.nix
        ├── git.nix
        ├── tmux.nix
        ├── font.nix
        ├── neovim.nix
        └── ...
```

## Flake Outputs

- `nixosConfigurations.epsilon`
- `nixosConfigurations.zeta`
- `homeConfigurations."iperez@delta"`
- `homeConfigurations."iperez@epsilon"`
- `homeConfigurations."iperez@zeta"`
- `homeConfigurations."iperez@zeta-thin"`

## AI Harness

Shared configuration for the local AI coding agents (`pi`, `opencode`, Claude Code, Codex), wired through `home-manager/global/ai-harness.nix`. Canonical assets live in `ai/`; secret values never do.

### First-time setup

Activation aborts early if the secret env files are missing. Create them once per machine (mode `600`, never committed):

```bash
mkdir -p ~/.config/ai-harness/secrets
# mcp.env — export ATLAS_TOKEN=... and CONTEXT7_API_KEY=...
# api.env — may be empty; only needs to exist
touch ~/.config/ai-harness/secrets/{mcp.env,api.env}
chmod 600 ~/.config/ai-harness/secrets/*.env
```

Required variable names are listed in `ai/support/secrets-env-contract.md`.

### How assets reach each agent

| Mechanism | Used for | On disk |
|-----------|----------|---------|
| **Projection** (symlink) | Static assets: skills, agents, commands, prompts | `/nix/store` symlinks. A recursive directory becomes a real directory whose leaf files are the symlinks. |
| **Rendered secret config** | Files the harness fully owns | Whole-file render at activation: `@VAR@` → value from the env files, written `600`. Targets: `.config/opencode/opencode.jsonc`, `.pi/agent/mcp.json`. |
| **Merged config** | Files the agent rewrites at runtime | Only the MCP / permissions section is injected; all other runtime state (OAuth, project trust, caches) is preserved. Targets: `.claude.json`, `.codex/config.toml`, `.claude/settings.json`. |

Switches are idempotent: projections re-point and configs re-merge on every `home-manager switch` — no manual file deletion is required. The projection preflight blocks a switch only when a **single-file** target already exists as an unmanaged file; recursive directory targets are left to Home Manager's native collision handling (see `ai/support/projection-preflight.md`).

Rendering and merging run in a small activation-time helper (`home-manager/global/ai-harness-{render,merge}.py`) because they operate on runtime secrets and agent-owned files that pure Nix evaluation cannot read. The symlink projections themselves are plain Home Manager, no scripting.

### MCP servers

The same MCP set is provisioned across agents (`aws`, `context7`, `figma`, `dbflux`, `engram`, `obsidian`, `atlas`), with per-agent adjustments — e.g. Claude Code omits `engram`/`figma` since those are already provided as plugins. Tokens are substituted from `mcp.env` at activation; the templates under `ai/` hold placeholders only.

## Notes

- WireGuard config is read from `~/.ssh/wireguard/default.nix` (not in repo)
- `hosts/zeta/hardware-configuration.nix` comes from the current zeta install and must be regenerated if disk layout changes
- X11 window manager configs are kept for future use, just not imported
- Epsilon uses Hyprland (Wayland) with Ghostty terminal and Wofi launcher
