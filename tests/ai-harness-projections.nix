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
    "ai/grok/AGENTS.md"
    "ai/grok/ORCHESTRATOR.md"
    "ai/grok/agents/worker.md"
    "ai/grok/agents/reviewer.md"
    "ai/grok/mcp-servers.toml"
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
    ".grok/AGENTS.md"
    ".grok/ORCHESTRATOR.md"
    ".grok/agents"
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
    ".grok/AGENTS.md"
    ".grok/ORCHESTRATOR.md"
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
  # Judgment Day still uses a scoped ledger/re-judge contract when the user
  # opts in. Orchestrators no longer embed the full RDD Review Execution Contract.
  judgmentDayLedgerAssets = [
    "ai/opencode/skills/judgment-day/SKILL.md"
    "ai/claude/skills/judgment-day/SKILL.md"
  ];
  explicitReviewPolicyAssets = [
    "ai/shared/ORCHESTRATOR.md"
    "ai/opencode/ORCHESTRATOR.md"
    "ai/claude/sdd-orchestrator.md"
    "ai/codex/sdd-orchestrator.md"
    "ai/grok/ORCHESTRATOR.md"
  ];
  trimLine =
    line:
    let
      match = builtins.match "^[[:space:]]*(.*[^[:space:]])[[:space:]]*$" line;
    in
    if match == null then "" else builtins.elemAt match 0;
  jsoncLines = builtins.filter (line: !(flake.inputs.nixpkgs.lib.hasPrefix "//" (trimLine line))) (
    flake.inputs.nixpkgs.lib.splitString "\n" (
      builtins.readFile (flakePath + "/ai/opencode/opencode.jsonc")
    )
  );
  normalizedJsoncLines = flake.inputs.nixpkgs.lib.imap0 (
    index: line:
    let
      hasNext = index + 1 < builtins.length jsoncLines;
      nextLine = if hasNext then trimLine (builtins.elemAt jsoncLines (index + 1)) else "";
      nextClosesValue =
        flake.inputs.nixpkgs.lib.hasPrefix "}" nextLine || flake.inputs.nixpkgs.lib.hasPrefix "]" nextLine;
    in
    if nextClosesValue then flake.inputs.nixpkgs.lib.removeSuffix "," (trimLine line) else line
  ) jsoncLines;
  opencodeConfig = builtins.fromJSON (
    flake.inputs.nixpkgs.lib.concatStringsSep "\n" normalizedJsoncLines
  );
  expectedAgentModels = {
    sdd-orchestrator = "openai/gpt-5.6-sol";
    sdd-onboard = "openai/gpt-5.6-sol";
    sdd-apply = "openai/gpt-5.6-terra";
    sdd-archive = "openai/gpt-5.6-luna";
    sdd-design = "openai/gpt-5.6-sol";
    sdd-explore = "openai/gpt-5.6-luna";
    sdd-init = "openai/gpt-5.6-luna";
    sdd-propose = "openai/gpt-5.6-sol";
    sdd-spec = "openai/gpt-5.6-luna";
    sdd-tasks = "openai/gpt-5.6-luna";
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
    bug-hunter = "allow";
    pr-reviewer = "allow";
    research = "allow";
    researcher = "allow";
    reviewer = "allow";
    scout = "allow";
    worker = "allow";
    sdd-apply = "allow";
    sdd-archive = "allow";
    sdd-design = "allow";
    sdd-explore = "allow";
    sdd-init = "allow";
    sdd-onboard = "allow";
    sdd-propose = "allow";
    sdd-spec = "allow";
    sdd-tasks = "allow";
    sdd-verify = "allow";
    sdd-explore-testing = "allow";
    sdd-plan-testing = "allow";
    sdd-run-testing = "allow";
    sdd-report-testing = "allow";
  };
  multiOverlay = builtins.fromJSON (
    builtins.readFile (flakePath + "/ai/opencode/sdd-overlay-multi.json")
  );
  singleOverlay = builtins.fromJSON (
    builtins.readFile (flakePath + "/ai/opencode/sdd-overlay-single.json")
  );
  portableTrustContractAssets = [
    "ai/shared/ORCHESTRATOR.md"
    "ai/claude/sdd-orchestrator.md"
    "ai/codex/sdd-orchestrator.md"
    "ai/opencode/ORCHESTRATOR.md"
  ];
  portableTrustContractObligations = [
    {
      name = "lossless choice retention";
      needles = [
        "every question, option, default, consequence, and answer syntax"
        "block for an answer"
        "do not infer or silently discard a choice"
      ];
    }
    {
      name = "requirement-preserving handoffs";
      needles = [
        "explicit requirements, constraints, acceptance criteria, and assigned scope"
        "within that scope"
        "must not claim work or completion they did not perform"
      ];
    }
    {
      name = "truthful failure handoff";
      needles = [
        "report the failure as it occurred"
        "preserve the uncompleted work and next actionable state"
        "do not present the result as successful"
      ];
    }
    {
      name = "observed-evidence reporting";
      needles = [
        "observed evidence"
        "naming the command, artifact, tool result"
        "distinguish observed facts from inferences"
      ];
    }
    {
      name = "claim verification";
      needles = [
        "against available evidence"
        "If verification is unavailable"
        "next action needed to verify it"
      ];
    }
  ];
  onboardingCommand = "ai/opencode/commands/sdd-onboard.md";
  onboardingPrompt = "ai/opencode/prompts/sdd/sdd-onboard.md";
  contradictoryPolicyNeedles = [
    "RDD is required"
    "require RDD"
    "must produce RDD receipts"
    "generate RDD receipts"
    "automatically run 4R"
    "automatically launch 4R"
    "automatically run Judgment Day"
    "run 4R automatically"
    "run Judgment Day automatically"
    "automatically launch a refuter"
    "refuter majority decides"
    "open a PR after"
    "create a PR after"
    "must open a PR"
    "require a PR for delivery"
    "route delivery through a PR"
  ];
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
  fileIncludes =
    relativePath: needle:
    flake.inputs.nixpkgs.lib.hasInfix needle (builtins.readFile (flakePath + "/" + relativePath));
  maestroMcpTemplates = [
    {
      file = "ai/agens/config.toml";
      needles = [
        "[mcp.maestro]"
        "transport = \"stdio\""
        "command = \"maestro\""
        "args = [\"mcp\"]"
      ];
    }
    {
      file = "ai/pi/mcp.json";
      needles = [
        "\"maestro\": {"
        "\"command\": \"maestro\""
        "\"args\": [\"mcp\"]"
      ];
    }
    {
      file = "ai/opencode/opencode.jsonc";
      needles = [
        "\"maestro\": {"
        "\"maestro\""
        "\"mcp\""
        "\"enabled\": true"
        "\"type\": \"local\""
      ];
    }
    {
      file = "ai/claude/mcp-servers.json";
      needles = [
        "\"maestro\": {"
        "\"command\": \"maestro\""
        "\"mcp\""
      ];
    }
    {
      file = "ai/codex/mcp-servers.toml";
      needles = [
        "[mcp_servers.maestro]"
        "command = \"maestro\""
        "args = [\"mcp\"]"
      ];
    }
    {
      file = "ai/grok/mcp-servers.toml";
      needles = [
        "[mcp_servers.maestro]"
        "command = \"maestro\""
        "args = [\"mcp\"]"
      ];
    }
  ];
  hasMaestroPackage =
    packages:
    builtins.any (
      package:
      (package.pname or "") == "maestro" || builtins.match "maestro-[0-9].*" (package.name or "") != null
    ) packages;
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
      # Canonical projection sources are materialized from the managed asset tree,
      # whose store path is named `ai-harness` (see ai-harness.nix). Match that,
      # not a literal `/ai/` segment, which a /nix/store/<hash>-ai-harness path
      # never contains. This excludes the pi-harness input's own `-source` assets.
      canonicalSources = builtins.filter (
        source: builtins.match ".*-ai-harness/.*" source != null
      ) sources;
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
  check: builtins.all (needle: fileIncludes check.file needle) check.needles
) maestroMcpTemplates;
assert
  opencodeConfig.mcp.maestro == {
    type = "local";
    enabled = true;
    command = [
      "maestro"
      "mcp"
    ];
  };
assert builtins.all (
  host: hasMaestroPackage flake.homeConfigurations.${host}.config.home.packages
) (hosts ++ [ "iperez@pi" ]);
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
assert opencodeConfig.default_agent == "sdd-orchestrator";
assert opencodeConfig.agent.sdd-orchestrator.mode == "primary";
assert opencodeConfig.agent.sdd-orchestrator.tools.grep;
assert opencodeConfig.agent.sdd-orchestrator.permission.question == "allow";
assert opencodeConfig.agent.sdd-orchestrator.tools.question;
assert opencodeConfig.agent.sdd-onboard.hidden;
assert opencodeConfig.agent.sdd-onboard.mode == "subagent";
assert opencodeConfig.agent.sdd-onboard.prompt == "{file:/home/iperez/.config/opencode/prompts/sdd/sdd-onboard.md}";
assert opencodeConfig.agent.sdd-onboard.tools.read;
assert opencodeConfig.agent.sdd-onboard.tools.write;
assert !(opencodeConfig.agent.sdd-onboard.tools ? task);
assert !(opencodeConfig.agent.sdd-onboard.tools ? delegate);
assert assetExists onboardingPrompt;
assert builtins.all (needle: fileIncludes onboardingCommand needle) [
  "agent: sdd-orchestrator"
  "existing SDD preflight decision block"
  "every question, option, default, consequence, and answer syntax"
  "Engram `mem_current_project`"
  "returned project value unchanged"
  "hidden `sdd-onboard` agent"
  "working directory, artifact-store mode, and complete preflight decision block"
  "Relay a blocked-choice envelope losslessly"
];
assert builtins.all (needle: fileIncludes onboardingPrompt needle) [
  "SDD executor for onboarding, not the orchestrator"
  "Do NOT delegate, do NOT call task/delegate, and do NOT launch sub-agents"
  "injected working directory, project, artifact-store mode, and preflight decision block"
  "Do not replace an injected value or infer a missing user choice"
  "blocking envelope that preserves every question, option, default, consequence, and answer syntax"
  "Stop after returning that envelope"
  "status`, `executive_summary`, `artifacts`, and `next_recommended`"
];
assert !(opencodeConfig.agent.sdd-verify.tools ? edit);
assert !(opencodeConfig.agent.sdd-explore.tools ? edit);
assert opencodeConfig.agent.sdd-apply.tools.edit;
assert multiOverlay.agent.sdd-orchestrator.permission.task.__replace__.general == "allow";
assert multiOverlay.agent.sdd-orchestrator.permission.task.__replace__.explore == "allow";
assert multiOverlay.agent.sdd-orchestrator.permission.question == "allow";
assert multiOverlay.agent.sdd-orchestrator.tools.question;
assert singleOverlay.agent.sdd-orchestrator.permission.task.__replace__.general == "allow";
assert singleOverlay.agent.sdd-orchestrator.permission.task.__replace__.explore == "allow";
assert singleOverlay.agent.sdd-orchestrator.permission.question == "allow";
assert singleOverlay.agent.sdd-orchestrator.tools.question;
assert builtins.all (
  relativePath:
  builtins.all (
    obligation: builtins.all (needle: fileIncludes relativePath needle) obligation.needles
  ) portableTrustContractObligations
) portableTrustContractAssets;
assert builtins.all (
  relativePath:
  builtins.all (needle: fileIncludes relativePath needle) [
    "RDD-style receipts"
    "never automatic"
    "There is no PR auto-review rule"
  ]
) portableTrustContractAssets;
assert builtins.all (
  relativePath: builtins.all (needle: fileDoesNotContain relativePath needle) contradictoryPolicyNeedles
) portableTrustContractAssets;
assert builtins.all (
  relativePath: fileDoesNotContain relativePath ".atl/"
) portableTrustContractAssets;
assert builtins.all (
  relativePath:
  builtins.all (needle: fileContains relativePath needle) [
    "BLOCKER/CRITICAL IDs"
    "initial path set"
    "acceptance criteria"
    "regression evidence"
  ]
) judgmentDayLedgerAssets;
assert builtins.all (
  relativePath:
  builtins.all (needle: fileContains relativePath needle) [
    "Explicit Review Protocols"
    "Judgment Day"
    "4R"
    "Automatic Mode Continuity"
  ]
) explicitReviewPolicyAssets;
assert builtins.all (check: builtins.all (needle: fileContains check.file needle) check.needles) [
  {
    file = "ai/opencode/ORCHESTRATOR.md";
    needles = [
      "native `explore` agent"
      "native `general` agent"
      "Quiet batch cycle"
      "never automatic"
    ];
  }
  {
    file = "ai/shared/ORCHESTRATOR.md";
    needles = [
      "never automatic"
      "Quiet batch cycle"
    ];
  }
  {
    file = "ai/claude/sdd-orchestrator.md";
    needles = [
      "never automatic"
      "separate"
    ];
  }
  {
    file = "ai/grok/AGENTS.md";
    needles = [
      "spawn_subagent"
      "Explicit reviews"
      "4R"
    ];
  }
  {
    file = "ai/grok/mcp-servers.toml";
    needles = [
      "@ATLAS_TOKEN@"
      "@CONTEXT7_API_KEY@"
      "@PENPOT_API_KEY@"
    ];
  }
  {
    file = "ai/shared/engram-protocol.md";
    needles = [
      "DELIVERY GUARANTEE"
      "never blocks"
    ];
  }
  {
    file = "ai/claude/engram-protocol.md";
    needles = [
      "DELIVERY GUARANTEE"
      "never blocks"
    ];
  }
  {
    file = "ai/opencode/ORCHESTRATOR.md";
    needles = [
      "Delivery guarantee"
      "must never block"
    ];
  }
];
assert builtins.all
  (
    relativePath:
    builtins.all (needle: fileDoesNotContain relativePath needle) [
      "review-start"
      "review-resume"
      "review-validate"
      "transaction locks"
      "Git-derived snapshots"
      "authoritative Engram receipts"
      "append-only CAS"
      "Lifecycle receipt rule"
      "gentle-ai review status"
    ]
  )
  [
    "ai/shared/ORCHESTRATOR.md"
    "ai/opencode/ORCHESTRATOR.md"
    "ai/claude/sdd-orchestrator.md"
    "ai/codex/sdd-orchestrator.md"
    "ai/grok/ORCHESTRATOR.md"
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
