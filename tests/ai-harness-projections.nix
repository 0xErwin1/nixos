{ flake, flakePath }:

let
  hosts = [
    "iperez@delta"
    "iperez@epsilon"
    "iperez@zeta"
  ];
  canonicalAssets = [
    "ai/skills/_shared/obsidian-convention.md"
    "ai/opencode/AGENTS.md"
    "ai/opencode/ORCHESTRATOR.md"
    "ai/opencode/agent/scout.md"
    "ai/opencode/commands/sdd-apply.md"
    "ai/shared/engram-protocol.md"
    "ai/claude/CLAUDE.md"
    "ai/claude/sdd-orchestrator.md"
    "ai/claude/engram-protocol.md"
    "ai/claude/agents/sdd-apply.md"
    "ai/claude/commands/sdd-apply.md"
    "ai/codex/AGENTS.md"
    "ai/codex/sdd-orchestrator.md"
    "ai/codex/engram-instructions.md"
    "ai/codex/engram-compact-prompt.md"
    "ai/codex/commands/sdd-test.md"
    "ai/codex/agents/sdd-run-testing.md"
    "ai/support/secrets-env-contract.md"
    "ai/support/operator-cutover-rollback.md"
  ];
  expectedTargets = [
    ".agents/skills"
    ".config/opencode/AGENTS.md"
    ".config/opencode/ORCHESTRATOR.md"
    ".config/opencode/agent"
    ".config/opencode/commands"
    ".config/opencode/command"
    ".config/opencode/skills"
    ".config/opencode/tui.json"
    ".claude/CLAUDE.md"
    ".claude/sdd-orchestrator.md"
    ".claude/engram-protocol.md"
    ".claude/agents"
    ".claude/commands"
    ".claude/skills"
    ".codex/AGENTS.md"
    ".codex/sdd-orchestrator.md"
    ".codex/engram-instructions.md"
    ".codex/engram-compact-prompt.md"
    ".codex/commands"
    ".codex/agents"
    ".codex/skills"
  ];
  # Single-file projection targets: Home Manager materializes each as a
  # whole-path /nix/store symlink, so the unmanaged-collision preflight guards
  # exactly these. Recursive directory targets become real directories with
  # symlinked leaves, so the preflight intentionally skips them (guarding the
  # directory's top level would abort on every switch after the first).
  expectedFileTargets = [
    ".config/opencode/AGENTS.md"
    ".config/opencode/ORCHESTRATOR.md"
    ".config/opencode/tui.json"
    ".claude/CLAUDE.md"
    ".claude/sdd-orchestrator.md"
    ".claude/engram-protocol.md"
    ".codex/AGENTS.md"
    ".codex/sdd-orchestrator.md"
    ".codex/engram-instructions.md"
    ".codex/engram-compact-prompt.md"
  ];
  recursiveTargetSample = ".agents/skills";
  expectedSecretEnv = {
    AI_HARNESS_MCP_ENV_FILE = "/home/iperez/.config/ai-harness/secrets/mcp.env";
    AI_HARNESS_API_ENV_FILE = "/home/iperez/.config/ai-harness/secrets/api.env";
  };
  renderedSecretTargets = [
    ".config/opencode/opencode.jsonc"
  ];
  renderedTemplateChecks = [
    {
      file = "ai/opencode/opencode.jsonc";
      placeholders = [
        "@ATLAS_TOKEN@"
        "@CONTEXT7_API_KEY@"
        "@PENPOT_API_KEY@"
      ];
    }
  ];
  frozenLedgerAssets = [
    "ai/shared/ORCHESTRATOR.md"
    "ai/opencode/ORCHESTRATOR.md"
    "ai/claude/sdd-orchestrator.md"
    "ai/claude/agents/jd-judge-a.md"
    "ai/claude/agents/jd-judge-b.md"
    "ai/claude/agents/review-readability.md"
    "ai/claude/agents/review-resilience.md"
    "ai/claude/agents/review-risk.md"
    "ai/opencode/skills/judgment-day/SKILL.md"
    "ai/opencode/skills/judgment-day/references/prompts-and-formats.md"
    "ai/claude/skills/judgment-day/SKILL.md"
    "ai/claude/skills/judgment-day/references/prompts-and-formats.md"
  ];
  trimLine = line:
    let
      match = builtins.match "^[[:space:]]*(.*[^[:space:]])[[:space:]]*$" line;
    in
    if match == null then "" else builtins.elemAt match 0;
  jsoncLines = builtins.filter (
    line: !(flake.inputs.nixpkgs.lib.hasPrefix "//" (trimLine line))
  ) (flake.inputs.nixpkgs.lib.splitString "\n" (builtins.readFile (flakePath + "/ai/opencode/opencode.jsonc")));
  normalizedJsoncLines = flake.inputs.nixpkgs.lib.imap0 (
    index: line:
    let
      hasNext = index + 1 < builtins.length jsoncLines;
      nextLine = if hasNext then trimLine (builtins.elemAt jsoncLines (index + 1)) else "";
      nextClosesValue =
        flake.inputs.nixpkgs.lib.hasPrefix "}" nextLine
        || flake.inputs.nixpkgs.lib.hasPrefix "]" nextLine;
    in
    if nextClosesValue then flake.inputs.nixpkgs.lib.removeSuffix "," (trimLine line) else line
  ) jsoncLines;
  opencodeConfig = builtins.fromJSON (
    flake.inputs.nixpkgs.lib.concatStringsSep "\n" normalizedJsoncLines
  );
  expectedAgentModels = {
    sdd-orchestrator = "openai/gpt-5.6-sol";
    sdd-apply = "openai/gpt-5.6-terra";
    sdd-archive = "openai/gpt-5.6-terra";
    sdd-design = "openai/gpt-5.6-sol";
    sdd-explore = "openai/gpt-5.6-terra";
    sdd-init = "openai/gpt-5.6-terra";
    sdd-propose = "openai/gpt-5.6-sol";
    sdd-spec = "openai/gpt-5.6-terra";
    sdd-tasks = "openai/gpt-5.6-terra";
    sdd-verify = "openai/gpt-5.6-sol";
  };
  expectedOpenCodePermissions = {
    bash = {
      "*" = "allow";
      "git commit *" = "ask";
      "git push" = "ask";
      "git push *" = "ask";
      "git push --force *" = "ask";
      "git rebase *" = "ask";
      "git reset --hard *" = "ask";
    };
    external_directory = {
      "**" = "allow";
      "/nix/store/**" = "allow";
    };
    read = {
      "**/.env" = "deny";
      "**/.env.*" = "deny";
      "*.env" = "deny";
      "*.env.*" = "deny";
      "**/credentials.json" = "deny";
      "**/.credentials.json" = "deny";
      "**/auth.json" = "deny";
      "**/.auth.json" = "deny";
      "**/secrets/**" = "deny";
    };
  };
  actualAgentModels = flake.inputs.nixpkgs.lib.mapAttrs (
    _: agent: agent.model or null
  ) opencodeConfig.agent;
  expectedNativeTaskPermissions = {
    "*" = "deny";
    explore = "allow";
    general = "allow";
    reviewer = "allow";
    worker = "allow";
    sdd-apply = "allow";
    sdd-archive = "allow";
    sdd-design = "allow";
    sdd-explore = "allow";
    sdd-init = "allow";
    sdd-propose = "allow";
    sdd-spec = "allow";
    sdd-tasks = "allow";
    sdd-verify = "allow";
  };
  multiOverlay = builtins.fromJSON (
    builtins.readFile (flakePath + "/ai/opencode/sdd-overlay-multi.json")
  );
  singleOverlay = builtins.fromJSON (
    builtins.readFile (flakePath + "/ai/opencode/sdd-overlay-single.json")
  );
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
    "sqlite"
    "wal"
    "socket"
    "pid"
    "telemetry"
    "token"
    "secret"
  ];
  forbiddenTargets = [
    ".pi/agent/settings.json"
    ".pi/agent/mcp.json"
    ".codex/config.toml"
    ".claude/settings.json"
    ".claude/claude.json"
  ];
  hasFragment = fragment: target: builtins.match (".*" + fragment + ".*") target != null;
  unique = values: builtins.length values == builtins.length (flake.inputs.nixpkgs.lib.unique values);
  assetExists = relativePath: builtins.pathExists (flakePath + "/" + relativePath);
  fileContains =
    relativePath: needle:
    builtins.match (".*" + needle + ".*") (builtins.readFile (flakePath + "/" + relativePath)) != null;
  fileDoesNotContain = relativePath: needle: !(fileContains relativePath needle);
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
      renderActivation = homeConfiguration.config.home.activation.aiHarnessSecretConfigRender.data;
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
      targetsAvoidForbiddenState = builtins.all (
        target: !(builtins.elem target forbiddenTargets)
      ) targets;
      canonicalSources = builtins.filter (source: builtins.match (".*/ai/.*") source != null) sources;
      sourcesAvoidTabularium = builtins.all (
        source: builtins.match ".*/\\.tabularium/.*" source == null
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
      ) expectedFileTargets;
      activationSkipsRecursiveTargets =
        builtins.match (".*" + recursiveTargetSample + ".*") activation == null;
      activationBlocksUnmanagedFiles =
        builtins.match ".*already exists and is not a Home Manager symlink.*" activation != null;
      activationBlocksUnmanagedSymlinks =
        builtins.match ".*already exists as an unmanaged symlink.*" activation != null;
      activationAllowsNixStoreSymlinks = builtins.match ".*/nix/store/\\*.*" activation != null;
      renderedSecretConfigsNotProjected = builtins.all (
        target: !(builtins.elem target targets)
      ) renderedSecretTargets;
      renderMentionsRenderedTargets = builtins.all (
        target: builtins.match (".*" + target + ".*") renderActivation != null
      ) renderedSecretTargets;
      renderSourcesSecretEnvFiles = builtins.all (
        path: builtins.match (".*" + path + ".*") renderActivation != null
      ) expectedSecretPaths;
    };
  states = map hostState hosts;
  validState =
    state:
    state.hasExpectedTargets
    && state.targetsAreUnique
    && state.targetsAvoidRuntimeState
    && state.targetsAvoidForbiddenState
    && builtins.length state.canonicalSources >= builtins.length expectedTargets
    && state.sourcesAvoidTabularium
    && state.exposesOnlySecretPathReferences
    && state.exposesNoInlineSecretEnvironment
    && state.generatedEnvFileMentionsOnlyPathsAndNames
    && state.secretPreflightMentionsPaths
    && state.secretPreflightReportsMissingFiles
    && state.activationMentionsTargets
    && state.activationSkipsRecursiveTargets
    && state.activationBlocksUnmanagedFiles
    && state.activationBlocksUnmanagedSymlinks
    && state.activationAllowsNixStoreSymlinks
    && state.renderedSecretConfigsNotProjected
    && state.renderMentionsRenderedTargets
    && state.renderSourcesSecretEnvFiles;
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
assert builtins.all (
  check:
  builtins.all (placeholder: fileContains check.file placeholder) check.placeholders
  && !(fileHasTokenLikeAssignment check.file)
) renderedTemplateChecks;
assert actualAgentModels == expectedAgentModels;
assert opencodeConfig.permission == expectedOpenCodePermissions;
assert opencodeConfig.agent.sdd-orchestrator.permission.task == expectedNativeTaskPermissions;
assert multiOverlay.agent.sdd-orchestrator.permission.task.__replace__.general == "allow";
assert multiOverlay.agent.sdd-orchestrator.permission.task.__replace__.explore == "allow";
assert singleOverlay.agent.sdd-orchestrator.permission.task.__replace__.general == "allow";
assert singleOverlay.agent.sdd-orchestrator.permission.task.__replace__.explore == "allow";
assert builtins.all (
  relativePath:
  builtins.all (needle: fileContains relativePath needle) [
    "BLOCKER/CRITICAL IDs"
    "initial path set"
    "acceptance criteria"
    "regression evidence"
    "non-blocking follow-ups"
  ]
) frozenLedgerAssets;
assert builtins.all (
  check: builtins.all (needle: fileContains check.file needle) check.needles
) [
  {
    file = "ai/opencode/ORCHESTRATOR.md";
    needles = [ "native `explore` agent" "native `general` agent" "non-blocking follow-ups" ];
  }
  {
    file = "ai/shared/ORCHESTRATOR.md";
    needles = [ "initial path set" "non-blocking follow-ups" ];
  }
  {
    file = "ai/claude/sdd-orchestrator.md";
    needles = [ "initial path set" "non-blocking follow-ups" ];
  }
  {
    file = "ai/shared/engram-protocol.md";
    needles = [ "DELIVERY GUARANTEE" "never blocks" ];
  }
  {
    file = "ai/claude/engram-protocol.md";
    needles = [ "DELIVERY GUARANTEE" "never blocks" ];
  }
  {
    file = "ai/opencode/ORCHESTRATOR.md";
    needles = [ "Delivery guarantee" "must never block" ];
  }
];
assert builtins.all (
  relativePath:
  builtins.all (needle: fileDoesNotContain relativePath needle) [
    "review-start"
    "review-resume"
    "review-validate"
    "transaction locks"
    "Git-derived snapshots"
    "authoritative Engram receipts"
    "append-only CAS"
  ]
) [
  "ai/shared/ORCHESTRATOR.md"
  "ai/opencode/ORCHESTRATOR.md"
  "ai/claude/sdd-orchestrator.md"
  "ai/opencode/skills/judgment-day/SKILL.md"
  "ai/claude/skills/judgment-day/SKILL.md"
];
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
