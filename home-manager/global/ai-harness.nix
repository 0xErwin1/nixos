{ lib, ... }:

let
  canonicalRoot = ../../ai;

  projectedResources = [
    {
      source = canonicalRoot + "/support/home-manager-canonical-assets.md";
      target = ".pi/agent/support/home-manager-canonical-assets.md";
    }
    {
      source = canonicalRoot + "/support/home-manager-canonical-assets.md";
      target = ".config/opencode/support/home-manager-canonical-assets.md";
    }
  ];

  projectionTargets = map (resource: resource.target) projectedResources;
  projectionSources = map (resource: resource.source) projectedResources;
  shellTargets = lib.concatMapStringsSep " " (target: lib.escapeShellArg target) projectionTargets;
in
{
  assertions = [
    {
      assertion = lib.length projectionTargets == lib.length (lib.unique projectionTargets);
      message = "AI harness projection targets must be unique.";
    }
    {
      assertion = lib.all builtins.pathExists projectionSources;
      message = "AI harness projection sources must exist under the canonical Home Manager ai/ tree.";
    }
  ];

  programs.pi.coding-agent.resources = lib.mkAfter projectedResources;

  home.activation.aiHarnessProjectionPreflight = lib.hm.dag.entryBefore [ "writeBoundary" ] ''
    set -eu

    for target in ${shellTargets}; do
      target_path="$HOME/$target"

      if [ -L "$target_path" ]; then
        link_target="$(readlink "$target_path")"
        case "$link_target" in
          /nix/store/*) ;;
          *)
            echo "AI harness projection target already exists as an unmanaged symlink: $target_path -> $link_target" >&2
            echo "Move or back up the unmanaged symlink before running home-manager switch." >&2
            exit 1
            ;;
        esac
      elif [ -e "$target_path" ]; then
        echo "AI harness projection target already exists and is not a Home Manager symlink: $target_path" >&2
        echo "Move or back up the unmanaged file before running home-manager switch." >&2
        exit 1
      fi
    done
  '';
}
