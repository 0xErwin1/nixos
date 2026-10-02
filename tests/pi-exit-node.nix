# Run from the repository root:
# nix eval --impure --json --no-write-lock-file --expr \
#   'import ./tests/pi-exit-node.nix { flake = builtins.getFlake (toString ./.); }'
{ flake }:
let
  pi = flake.nixosConfigurations.pi.config;
  clients = map (name: flake.nixosConfigurations.${name}.config) [
    "epsilon"
    "zeta"
  ];
  hasExitFlag = flags: builtins.elem "--advertise-exit-node" flags;
in
assert pi.services.tailscale.enable;
assert pi.services.tailscale.useRoutingFeatures == "both";
assert hasExitFlag pi.services.tailscale.extraUpFlags;
assert hasExitFlag pi.services.tailscale.extraSetFlags;
assert builtins.elem "--accept-routes" pi.services.tailscale.extraUpFlags;
assert builtins.elem "--login-server=https://hs.iperez.dev" pi.services.tailscale.extraUpFlags;
assert pi.boot.kernel.sysctl."net.ipv4.conf.all.forwarding";
assert pi.boot.kernel.sysctl."net.ipv6.conf.all.forwarding";
assert pi.networking.firewall.checkReversePath == "loose";
# With the existing iptables backend, tailscaled owns forwarding and SNAT.
assert pi.networking.firewall.backend == "iptables";
assert !pi.networking.firewall.filterForward;
assert builtins.elem "tailscaled.service" pi.systemd.services.tailscaled-set.partOf;
assert builtins.all (client:
  client.services.tailscale.useRoutingFeatures == "client"
  && !hasExitFlag client.services.tailscale.extraUpFlags
  && !hasExitFlag client.services.tailscale.extraSetFlags
) clients;
{ result = "passed"; }
