{ pkgs, ... }:
let
  installKey = pkgs.writeShellApplication {
    name = "pi-wireguard-key-install";
    runtimeInputs = [ pkgs.coreutils pkgs.wireguard-tools ];
    text = ''
      set -euo pipefail
      if [ "$#" -ne 0 ]; then
        echo "pi-wireguard-key-install accepts no arguments" >&2
        exit 64
      fi
      key_dir=/var/lib/wireguard
      key_path="$key_dir/pi-host-private.key"
      tmp_path=
      cleanup() { if [ -n "$tmp_path" ]; then rm -f -- "$tmp_path"; fi; }
      trap cleanup EXIT HUP INT TERM
      install -d -o root -g root -m 0700 -- "$key_dir"
      tmp_path="$(mktemp "$key_dir/.pi-host-private.key.XXXXXX")"
      key="$(dd bs=1 count=46 status=none)"
      if [ "$(dd bs=1 count=1 status=none | wc -c)" -ne 0 ]; then
        echo "WireGuard key input is too large" >&2
        exit 65
      fi
      if ! printf '%s' "$key" | wg pubkey >/dev/null 2>&1; then
        echo "WireGuard key input is invalid" >&2
        exit 65
      fi
      printf '%s\n' "$key" > "$tmp_path"
      chown root:root "$tmp_path"
      chmod 0600 "$tmp_path"
      sync -f "$tmp_path"
      mv -f -- "$tmp_path" "$key_path"
      tmp_path=
      sync -f "$key_dir"
    '';
  };
in
{
  environment.systemPackages = [ installKey ];
  security.sudo.extraRules = [{
    users = [ "iperez" ];
    runAs = "root";
    commands = [{
      command = ''/run/current-system/sw/bin/pi-wireguard-key-install ""'';
      options = [ "NOPASSWD" ];
    }];
  }];
  networking.wg-quick.interfaces.wg0 = {
    address = [ "10.0.0.2/24" ];
    listenPort = 51820;
    mtu = 1300;
    privateKeyFile = "/var/lib/wireguard/pi-host-private.key";
    peers = [{
      publicKey = "wZBcXWnY+1i67PHLBqes/x5U920dJhtJ7i1RFPhiIDQ=";
      endpoint = "142.44.162.92:51820";
      allowedIPs = [ "10.0.0.0/24" "10.0.1.0/24" ];
      persistentKeepalive = 25;
    }];
  };

  systemd.services.wg-quick-wg0.unitConfig.ConditionPathExists =
    "/var/lib/wireguard/pi-host-private.key";
}
