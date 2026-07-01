{ flakePath }:

let
  flake = builtins.getFlake ("path:" + flakePath);
  hosts = [
    "iperez@delta"
    "iperez@epsilon"
    "iperez@zeta"
  ];
  canonicalAssets = [
    "ai/support/home-manager-canonical-assets.md"
    "ai/support/projection-preflight.md"
  ];
  expectedTargets = [
    ".pi/agent/support/home-manager-canonical-assets.md"
    ".config/opencode/support/home-manager-canonical-assets.md"
  ];
  runtimeTargetFragments = [
    "auth"
    "cache"
    "session"
    "history"
    "log"
    "sqlite"
    "wal"
    "socket"
    "pid"
    "telemetry"
    "token"
    "secret"
  ];
  knownCollisionTargets = [
    ".pi/agent/AGENTS.md"
    ".pi/agent/settings.json"
    ".pi/agent/mcp.json"
    ".config/opencode/AGENTS.md"
    ".config/opencode/opencode.jsonc"
    ".claude/CLAUDE.md"
    ".claude/settings.json"
    ".codex/AGENTS.md"
    ".codex/config.toml"
  ];
  hasFragment = fragment: target: builtins.match (".*" + fragment + ".*") target != null;
  unique = values: builtins.length values == builtins.length (flake.inputs.nixpkgs.lib.unique values);
  assetExists = relativePath: builtins.pathExists (flakePath + "/" + relativePath);
  hostState =
    host:
    let
      homeConfiguration = flake.homeConfigurations.${host};
      cfg = homeConfiguration.config.programs.pi.coding-agent;
      activation = homeConfiguration.config.home.activation.aiHarnessProjectionPreflight.data;
      targets = map (resource: resource.target) cfg.resources;
      sources = map (resource: toString resource.source) cfg.resources;
    in
    {
      inherit
        host
        targets
        sources
        activation
        ;
      hasExpectedTargets = builtins.all (target: builtins.elem target targets) expectedTargets;
      targetsAreUnique = unique targets;
      targetsAvoidRuntimeState = builtins.all (
        target: !(builtins.any (fragment: hasFragment fragment target) runtimeTargetFragments)
      ) expectedTargets;
      targetsAvoidKnownCollisions = builtins.all (
        target: !(builtins.elem target knownCollisionTargets)
      ) expectedTargets;
      canonicalSources = builtins.filter (
        source: builtins.match (".*/ai/support/.*") source != null
      ) sources;
      activationMentionsTargets = builtins.all (
        target: builtins.match (".*" + target + ".*") activation != null
      ) expectedTargets;
      activationBlocksUnmanagedFiles =
        builtins.match ".*already exists and is not a Home Manager symlink.*" activation != null;
      activationBlocksUnmanagedSymlinks =
        builtins.match ".*already exists as an unmanaged symlink.*" activation != null;
      activationAllowsNixStoreSymlinks = builtins.match ".*/nix/store/\\*.*" activation != null;
    };
  states = map hostState hosts;
  validState =
    state:
    state.hasExpectedTargets
    && state.targetsAreUnique
    && state.targetsAvoidRuntimeState
    && state.targetsAvoidKnownCollisions
    && builtins.length state.canonicalSources >= builtins.length expectedTargets
    && state.activationMentionsTargets
    && state.activationBlocksUnmanagedFiles
    && state.activationBlocksUnmanagedSymlinks
    && state.activationAllowsNixStoreSymlinks;
in
assert builtins.all assetExists canonicalAssets;
assert builtins.all validState states;
{
  checkedHosts = hosts;
  inherit canonicalAssets expectedTargets states;
}
