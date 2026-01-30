# NixOS & Home Manager Configuration

Personal dotfiles managed with Nix flakes.

## Hosts

| Host | OS | Description |
|------|-----|-------------|
| `epsilon` | NixOS | ThinkPad - Hyprland (Wayland) |
| `delta` | Arch Linux | Standalone Home Manager |

## Usage

**NixOS (epsilon):**
```bash
sudo nixos-rebuild switch --flake .#epsilon
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
- `homeConfigurations."iperez@delta"`
- `homeConfigurations."iperez@epsilon"`

## Notes

- WireGuard config is read from `~/.ssh/wireguard/default.nix` (not in repo)
- X11 window manager configs are kept for future use, just not imported
- Epsilon uses Hyprland (Wayland) with Ghostty terminal and Wofi launcher
