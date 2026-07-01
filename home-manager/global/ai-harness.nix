{ config, lib, ... }:

let
  canonicalRoot = ../../ai;
  homeDirectory = config.home.homeDirectory;

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

  secretEnvContract = [
    {
      envVar = "AI_HARNESS_MCP_ENV_FILE";
      path = "${homeDirectory}/.config/ai-harness/secrets/mcp.env";
    }
    {
      envVar = "AI_HARNESS_API_ENV_FILE";
      path = "${homeDirectory}/.config/ai-harness/secrets/api.env";
    }
  ];

  secretEnvironment = lib.listToAttrs (
    map (entry: {
      name = entry.envVar;
      value = entry.path;
    }) secretEnvContract
  );

  projectionTargets = map (resource: resource.target) projectedResources;
  projectionSources = map (resource: resource.source) projectedResources;
  shellTargets = lib.concatMapStringsSep " " (target: lib.escapeShellArg target) projectionTargets;
  shellSecretEnvFiles = lib.concatMapStringsSep " " (
    entry: lib.escapeShellArg entry.path
  ) secretEnvContract;
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
    {
      assertion = lib.all (
        entry: builtins.match ".*(=|Bearer|sk-|gh[pousr]_|xox[baprs]-).*" entry.path == null
      ) secretEnvContract;
      message = "AI harness secret contract may reference only env file paths, not token-like values.";
    }
  ];

  programs.pi.coding-agent = {
    resources = lib.mkAfter projectedResources;
    environment = secretEnvironment;
  };

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

  home.activation.aiHarnessSecretsPreflight = lib.hm.dag.entryBefore [ "writeBoundary" ] ''
    set -eu

    for secret_env_file in ${shellSecretEnvFiles}; do
      if [ ! -f "$secret_env_file" ]; then
        echo "AI harness required env file is missing: $secret_env_file" >&2
        echo "Create the file locally with mode 600 before running home-manager switch; do not commit token values." >&2
        exit 1
      fi
    done
  '';
}
