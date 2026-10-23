# NixOS & Home Manager Configuration

Personal dotfiles managed with Nix flakes.

## Hosts

| Host | OS | Description |
|------|-----|-------------|
| `epsilon` | NixOS | ThinkPad - Hyprland (Wayland) |
| `zeta` | NixOS | ThinkPad x13 - Full-lite + thin (RDP) |
| `delta` | Arch Linux | Standalone Home Manager |
| `pi` | NixOS | Orange Pi 5 Plus - headless development host ([operations](docs/pi-operations.md)) |

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

The local AI coding clients (`pi`, `opencode`, Claude Code, Codex, Grok) and their shared harness are declared in `home-manager/global/ai.nix`. Gentle AI renders the harness itself; assets of our own (skills, policies, agents, commands, the Par persona) live in `ai/` and are layered onto the render. Secret values never live in the repository.

### First-time setup

Activation aborts early if the secret env files are missing. Create them once per machine (mode `600`, never committed):

```bash
mkdir -p ~/.config/ai-harness/secrets
# mcp.env — export the variables listed in ai/support/secrets-env-contract.md
# api.env — may be empty; only needs to exist
touch ~/.config/ai-harness/secrets/{mcp.env,api.env}
chmod 600 ~/.config/ai-harness/secrets/*.env
```

### How assets reach each agent

| Mechanism | Used for | On disk |
|-----------|----------|---------|
| **Rendered tree** | Everything Gentle AI renders plus `extraFiles` from `ai/` | Nix store symlinks. |
| **Secret paths** | Files carrying a credential once `@VAR@` placeholders resolve | Written at activation from the env files, mode `600`. |
| **Merged secrets** | Files the client also rewrites (`.claude.json`, `.claude/settings.json`, `.codex/config.toml`, `.pi/agent/settings.json`, `.pi/agent/mcp.json`) | Declared keys are merged in; OAuth, trust and other runtime state are preserved. |

### MCP servers

The shared set (`aws`, `context7`, `penpot`, `maestro`, `open-pencil`, `obsidian`, `dbflux-ui`) goes to every client; `atlas` and `dbflux` are per client, and `clickup` is Claude only. Tokens are substituted from `mcp.env` at activation.

## Notes

- WireGuard config is read from `~/.ssh/wireguard/default.nix` (not in repo)
- `hosts/zeta/hardware-configuration.nix` comes from the current zeta install and must be regenerated if disk layout changes
- X11 window manager configs are kept for future use, just not imported
- Epsilon uses Hyprland (Wayland) with Ghostty terminal and Wofi launcher
