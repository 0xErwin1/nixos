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
    "ai/support/secrets-env-contract.md"
    "ai/support/operator-cutover-rollback.md"
  ];
  expectedTargets = [
    ".pi/agent/support/home-manager-canonical-assets.md"
    ".config/opencode/support/home-manager-canonical-assets.md"
  ];
  expectedSecretEnv = {
    AI_HARNESS_MCP_ENV_FILE = "/home/iperez/.config/ai-harness/secrets/mcp.env";
    AI_HARNESS_API_ENV_FILE = "/home/iperez/.config/ai-harness/secrets/api.env";
  };
  expectedSecretPaths = builtins.attrValues expectedSecretEnv;
  expectedSecretVars = builtins.attrNames expectedSecretEnv;
  managedFilesToScan = [
    "ai/support/home-manager-canonical-assets.md"
    "ai/support/projection-preflight.md"
    "ai/support/secrets-env-contract.md"
    "ai/support/operator-cutover-rollback.md"
    "home-manager/global/ai-harness.nix"
    "home-manager/global/ai.nix"
    "tests/ai-harness-projections.nix"
  ];
  tokenLikeAssignmentPattern = ".*(Bearer[[:space:]]+[A-Za-z0-9._~+/=-]{20,}|sk-[A-Za-z0-9]{20,}|gh[pousr]_[A-Za-z0-9_]{20,}|xox[baprs]-[A-Za-z0-9-]{20,}|(api[_-]?key|token|secret|password)[[:space:]]*[:=][[:space:]]*[\"']?[A-Za-z0-9_./+-]{16,}).*";
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
  fileContains =
    relativePath: needle:
    builtins.match (".*" + needle + ".*") (builtins.readFile (flakePath + "/" + relativePath)) != null;
  fileHasTokenLikeAssignment =
    relativePath:
    builtins.match tokenLikeAssignmentPattern (builtins.readFile (flakePath + "/" + relativePath))
    != null;
  hostState =
    host:
    let
      homeConfiguration = flake.homeConfigurations.${host};
      cfg = homeConfiguration.config.programs.pi.coding-agent;
      activation = homeConfiguration.config.home.activation.aiHarnessProjectionPreflight.data;
      secretActivation = homeConfiguration.config.home.activation.aiHarnessSecretsPreflight.data;
      targets = map (resource: resource.target) cfg.resources;
      sources = map (resource: toString resource.source) cfg.resources;
      environment = cfg.environment;
      generatedEnvFile = homeConfiguration.config.home.file.".pi/agent/pi-harness-env.sh".text;
    in
    {
      inherit
        host
        targets
        sources
        activation
        secretActivation
        environment
        generatedEnvFile
        ;
      hasExpectedTargets = builtins.all (target: builtins.elem target targets) expectedTargets;
      targetsAreUnique = unique targets;
      targetsAvoidRuntimeState = builtins.all (
        target: !(builtins.any (fragment: hasFragment fragment target) runtimeTargetFragments)
      ) targets;
      targetsAvoidKnownCollisions = builtins.all (
        target: !(builtins.elem target knownCollisionTargets)
      ) targets;
      canonicalSources = builtins.filter (
        source: builtins.match (".*/ai/support/.*") source != null
      ) sources;
      exposesOnlySecretPathReferences = builtins.all (
        name: environment.${name} == expectedSecretEnv.${name}
      ) expectedSecretVars;
      exposesNoInlineSecretEnvironment = builtins.all (
        name: builtins.match tokenLikeAssignmentPattern ("${name} ${environment.${name}}") == null
      ) (builtins.attrNames environment);
      generatedEnvFileMentionsOnlyPathsAndNames =
        builtins.all (name: builtins.match (".*" + name + ".*") generatedEnvFile != null) expectedSecretVars
        && builtins.all (
          path: builtins.match (".*" + path + ".*") generatedEnvFile != null
        ) expectedSecretPaths
        && builtins.match tokenLikeAssignmentPattern generatedEnvFile == null;
      secretPreflightMentionsPaths = builtins.all (
        path: builtins.match (".*" + path + ".*") secretActivation != null
      ) expectedSecretPaths;
      secretPreflightReportsMissingFiles =
        builtins.match ".*AI harness required env file is missing.*" secretActivation != null;
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
    && state.exposesOnlySecretPathReferences
    && state.exposesNoInlineSecretEnvironment
    && state.generatedEnvFileMentionsOnlyPathsAndNames
    && state.secretPreflightMentionsPaths
    && state.secretPreflightReportsMissingFiles
    && state.activationMentionsTargets
    && state.activationBlocksUnmanagedFiles
    && state.activationBlocksUnmanagedSymlinks
    && state.activationAllowsNixStoreSymlinks;
in
assert builtins.all assetExists canonicalAssets;
assert builtins.all (
  relativePath:
  builtins.all (needle: fileContains relativePath needle) (expectedSecretPaths ++ expectedSecretVars)
) [ "ai/support/secrets-env-contract.md" ];
assert builtins.all (
  relativePath:
  builtins.all (needle: fileContains relativePath needle) [
    "home-manager switch"
    "manual"
    "rollback"
  ]
) [ "ai/support/operator-cutover-rollback.md" ];
assert builtins.all (relativePath: !(fileHasTokenLikeAssignment relativePath)) managedFilesToScan;
assert flake.checks.x86_64-linux ? ai-harness-readiness;
assert builtins.all validState states;
{
  checkedHosts = hosts;
  inherit
    canonicalAssets
    expectedTargets
    expectedSecretEnv
    states
    ;
}
