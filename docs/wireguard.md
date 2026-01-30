# WireGuard (vault.wireguard)

This repo's NixOS host config exposes `vault.wireguard` options to keep WireGuard secrets out of the Nix store.

## Private key file

Create a private key file on disk (example path used by the module):

```sh
sudo install -d -m 700 /etc/wireguard
sudo install -m 600 -o root -g root /dev/null /etc/wireguard/wg0.key

# Populate it (requires `wg` from wireguard-tools)
sudo sh -c 'umask 077; wg genkey > /etc/wireguard/wg0.key'
```

Requirements:

- Path: absolute (e.g. `/etc/wireguard/wg0.key`)
- Owner/group: `root:root`
- Permissions: `0600` (private key must not be readable by other users)

## NixOS configuration

Set these options in your NixOS host config (for example in `hosts/epsilon/default.nix` or another imported module):

```nix
{
  vault.wireguard = {
    enable = true;
    privateKeyFile = "/etc/wireguard/wg0.key";
    endpoint = "vpn.example.com:51820";
  };
}
```

Apply on NixOS:

```sh
sudo nixos-rebuild switch --flake .#epsilon
```

## Arch (non-NixOS)

`vault.wireguard` is a NixOS module option, so it does not apply on Arch. On Arch, manage WireGuard via `/etc/wireguard/wg0.conf` and restart the interface:

```sh
sudo systemctl restart wg-quick@wg0
```
