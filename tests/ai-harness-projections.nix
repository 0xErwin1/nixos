{ flake, flakePath, resourceMatrix ? import ../home-manager/global/ai-harness-resources.nix, runRuntimeTests ? false }:

let
  matrixFamilies = resourceMatrix.families;
  resourcesFor = delivery: builtins.filter (resource: resource.delivery or null == delivery) matrixFamilies;
  managedResources = builtins.filter (resource: resource.delivery or null != null) matrixFamilies;
  sourceTopLevelFamily = resource: builtins.elemAt (flake.inputs.nixpkgs.lib.splitString "/" resource.source) 0;
  actualAiFamilies = builtins.attrNames (builtins.readDir (flakePath + "/ai"));
  classifiedAiFamilies = flake.inputs.nixpkgs.lib.unique (map sourceTopLevelFamily matrixFamilies);
  deliveryFamilyNames = map (resource: resource.name) (resourcesFor "project" ++ resourcesFor "copy");
  agensCopyRoots = map (
    resource: flake.inputs.nixpkgs.lib.removePrefix "agens/" resource.source
  ) (builtins.filter (resource: resource.delivery or null == "copy") matrixFamilies);
  ownershipComplete = families: actualFamilies:
    let
      familyNames = map (resource: resource.name) families;
      sourceFamilies = flake.inputs.nixpkgs.lib.unique (map sourceTopLevelFamily families);
      deliveryNames = map (
        resource: resource.name
      ) (builtins.filter (resource: builtins.elem (resource.delivery or null) [ "project" "copy" ]) families);
    in
    builtins.all (family: builtins.elem family sourceFamilies) actualFamilies
    && flake.inputs.nixpkgs.lib.sort builtins.lessThan deliveryNames
      == flake.inputs.nixpkgs.lib.sort builtins.lessThan resourceMatrix.requiredDeliveryFamilyNames;
  removedAgensSkillsFixture = builtins.filter (resource: resource.name != "agens-skills") matrixFamilies;
  addedUnclassifiedFamilyFixture = actualAiFamilies ++ [ "unclassified-family" ];
  expectedTargets = map (resource: resource.target) (resourcesFor "project");
  expectedFileTargets = map (resource: resource.target) (builtins.filter (resource: !(resource.recursive or false)) (resourcesFor "project"));
  renderedSecretTargets = map (resource: resource.target) (resourcesFor "render");
  mergedSecretTargets = map (resource: resource.target) (resourcesFor "merge");
  managedSourcePaths = map (resource: "ai/${resource.source}") managedResources;
  retiredAssets = builtins.concatMap (resource: map (path: "ai/${path}") (resource.paths or [ ])) (builtins.filter (resource: resource.classification == "retired") matrixFamilies);
  retiredAssetAuthorityAssets = [
    "home-manager/global/ai-harness.nix"
    "ai/agens/generate.py"
  ] ++ map (path: "ai/${path}") resourceMatrix.providerParityReferences;
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
  grokSharedSkillNames = [
    "sdd-apply"
    "sdd-verify"
    "judgment-day"
  ];
  grokProjectedAgentNames = [
    "reviewer"
    "worker"
  ];
  grokReadme = "ai/grok/README.md";
  grokOrchestrator = "ai/grok/ORCHESTRATOR.md";
  grokGlobalPolicy = "ai/grok/AGENTS.md";
  grokAgentsDirectory = flakePath + "/ai/grok/agents";
  grokProjectedAgentFiles = builtins.attrNames (builtins.readDir grokAgentsDirectory);
  # Single-file projection targets: Home Manager materializes each as a
  # whole-path /nix/store symlink, so the unmanaged-collision preflight guards
  # exactly these. Recursive directory targets become real directories with
  # symlinked leaves, so the preflight intentionally skips them (guarding the
  # directory's top level would abort on every switch after the first).
  recursiveTargetSample = ".agents/skills";
  expectedSecretEnv = {
    AI_HARNESS_MCP_ENV_FILE = "/home/iperez/.config/ai-harness/secrets/mcp.env";
    AI_HARNESS_API_ENV_FILE = "/home/iperez/.config/ai-harness/secrets/api.env";
  };
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
  claudeReviewOwnerAssets = [
    "ai/claude/agents/review-risk.md"
    "ai/claude/agents/review-readability.md"
    "ai/claude/agents/review-reliability.md"
    "ai/claude/agents/review-resilience.md"
    "ai/claude/agents/jd-judge-a.md"
    "ai/claude/agents/jd-judge-b.md"
  ];
  claudeReviewOwnerForbiddenNeedles = [
    "refuter"
    "automatically launch a refuter"
    "voting"
    "majority"
    "empty ledger record"
    "fix → re-review"
    "fix rounds"
    "re-review loop"
  ];
  claudeJudgmentDayJudgeAssets = [
    "ai/claude/agents/jd-judge-a.md"
    "ai/claude/agents/jd-judge-b.md"
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
  retiredAssetReferenceNeedles = [
    "sdd-overlay-single.json"
    "sdd-overlay-multi.json"
    "ai/commands/"
    "skill-improver/skill-improver"
    ".atl/skill-registry.md"
  ];
  onboardingCommand = "ai/opencode/commands/sdd-onboard.md";
  onboardingPrompt = "ai/opencode/prompts/sdd/sdd-onboard.md";
  onboardingSkill = "ai/opencode/skills/sdd-onboard/SKILL.md";
  onboardingFallbackOwner = "ai/opencode/ORCHESTRATOR.md";
  onboardingFallbackConsumers = [
    onboardingCommand
    onboardingPrompt
    onboardingSkill
  ];
  sddCommandAssets = [
    "ai/opencode/commands/sdd-new.md"
    "ai/opencode/commands/sdd-continue.md"
    "ai/opencode/commands/sdd-ff.md"
    "ai/opencode/commands/sdd-init.md"
    "ai/opencode/commands/sdd-explore.md"
    "ai/opencode/commands/sdd-apply.md"
    "ai/opencode/commands/sdd-verify.md"
    "ai/opencode/commands/sdd-archive.md"
    "ai/opencode/commands/sdd-onboard.md"
    "ai/opencode/commands/sdd-test.md"
    "ai/opencode/commands/sdd-explore-testing.md"
    "ai/opencode/commands/sdd-plan-testing.md"
    "ai/opencode/commands/sdd-run-testing.md"
    "ai/opencode/commands/sdd-report-testing.md"
  ];
  sddStatusCommand = "ai/opencode/commands/sdd-status.md";
  opencodeCoordinationWorkflow = "ai/opencode/skills/_shared/sdd-orchestrator-workflow.md";
  opencodeWorkflowCoordinationNeedles = [
    "Status and artifact routing"
    "For `engram`, resolve status manually with `mem_search` then `mem_get_observation`."
    "For `openspec` or `hybrid`, the native dispatcher is authoritative when available."
    "Skill injection"
    "pass exact `SKILL.md` paths to every phase executor."
    "Exact apply scope and result reconciliation"
    "The executor implements only the assigned IDs, then stops."
    "Apply-progress continuity"
    "Completion, escalation, and synthesis"
    "The parent records completion only after reconciling the result with artifacts and repository evidence."
    "## Testing pipeline"
    "The suites approval is a user checkpoint."
  ];
  opencodeWorkflowForbiddenNeedles = [
    "RDD"
    "receipt"
    "ledger"
    "refuter"
    "delivery strategy"
    "chain strategy"
    "open a PR"
    "create a PR"
    "automatically run 4R"
    "automatically run Judgment Day"
  ];
  strictTddInitSkillAssets = [
    "ai/skills/sdd-init/SKILL.md"
    "ai/opencode/skills/sdd-init/SKILL.md"
    "ai/claude/skills/sdd-init/SKILL.md"
    "ai/codex/skills/sdd-init/SKILL.md"
  ];
  strictTddInitReferenceAssets = [
    "ai/skills/sdd-init/references/init-details.md"
    "ai/opencode/skills/sdd-init/references/init-details.md"
    "ai/claude/skills/sdd-init/references/init-details.md"
    "ai/codex/skills/sdd-init/references/init-details.md"
  ];
  strictTddApplySkillAssets = [
    "ai/skills/sdd-apply/SKILL.md"
    "ai/opencode/skills/sdd-apply/SKILL.md"
    "ai/claude/skills/sdd-apply/SKILL.md"
    "ai/codex/skills/sdd-apply/SKILL.md"
  ];
  strictTddVerifySkillAssets = [
    "ai/skills/sdd-verify/SKILL.md"
    "ai/opencode/skills/sdd-verify/SKILL.md"
    "ai/claude/skills/sdd-verify/SKILL.md"
    "ai/codex/skills/sdd-verify/SKILL.md"
  ];
  strictTddTasksSkillAssets = [
    "ai/skills/sdd-tasks/SKILL.md"
    "ai/opencode/skills/sdd-tasks/SKILL.md"
    "ai/claude/skills/sdd-tasks/SKILL.md"
    "ai/codex/skills/sdd-tasks/SKILL.md"
  ];
  strictTddForwardingAssets =
    strictTddInitSkillAssets
    ++ strictTddApplySkillAssets
    ++ strictTddVerifySkillAssets
    ++ [
      "ai/opencode/skills/_shared/sdd-orchestrator-workflow.md"
      "ai/claude/skills/_shared/sdd-orchestrator-workflow.md"
      "ai/codex/skills/_shared/sdd-orchestrator-workflow.md"
    ];
  effectiveLazyWorkflowAssets = [
    "ai/opencode/skills/_shared/sdd-orchestrator-workflow.md"
    "ai/claude/skills/_shared/sdd-orchestrator-workflow.md"
    "ai/codex/skills/_shared/sdd-orchestrator-workflow.md"
  ];
  staleStrictTddActivationPhrase = "Strict TDD Mode is activated when the project supports it";
  standardVerifyAssets = strictTddVerifySkillAssets;
  strictTddForwardingCases = [
    {
      strict_tdd_configured = false;
      runner_available = false;
      applicable_behavioral_boundary = false;
      forwarded = false;
    }
    {
      strict_tdd_configured = false;
      runner_available = false;
      applicable_behavioral_boundary = true;
      forwarded = false;
    }
    {
      strict_tdd_configured = false;
      runner_available = true;
      applicable_behavioral_boundary = false;
      forwarded = false;
    }
    {
      strict_tdd_configured = false;
      runner_available = true;
      applicable_behavioral_boundary = true;
      forwarded = false;
    }
    {
      strict_tdd_configured = true;
      runner_available = false;
      applicable_behavioral_boundary = false;
      forwarded = false;
    }
    {
      strict_tdd_configured = true;
      runner_available = false;
      applicable_behavioral_boundary = true;
      forwarded = false;
    }
    {
      strict_tdd_configured = true;
      runner_available = true;
      applicable_behavioral_boundary = false;
      forwarded = false;
    }
    {
      strict_tdd_configured = true;
      runner_available = true;
      applicable_behavioral_boundary = true;
      forwarded = true;
    }
  ];
  strictTddForwarded = inputs:
    inputs.strict_tdd_configured
    && inputs.runner_available
    && inputs.applicable_behavioral_boundary;
  commandForbiddenNeedles = [
    "subtask:"
    "mem_"
    "artifact-store"
    "Engram"
    "OpenSpec"
    "strict_tdd"
    "TDD"
    "$("
    "task("
    "delegate"
  ];
  sddPreflightContract = ''
    The single `question` call must contain these three localized groups in this order:

    1. Pace: Interactive, Automatic.
    2. Artifacts: Engram, OpenSpec, Both.
    3. Review: 400 lines, 800 lines, Other.
  '';
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
  normalFlowForbiddenNeedles = contradictoryPolicyNeedles ++ [
    "refuter"
    "delivery strategy"
    "chain strategy"
    "review workload guard"
    "suggested PR split"
    "PR shape"
  ];
  effectiveNormalFlowAssets = [
    "ai/shared/ORCHESTRATOR.md"
    "ai/opencode/ORCHESTRATOR.md"
    "ai/opencode/skills/_shared/sdd-orchestrator-workflow.md"
    "ai/claude/CLAUDE.md"
    "ai/claude/sdd-orchestrator.md"
    "ai/claude/skills/_shared/sdd-orchestrator-workflow.md"
    "ai/codex/AGENTS.md"
    "ai/codex/sdd-orchestrator.md"
    "ai/codex/skills/_shared/sdd-orchestrator-workflow.md"
    "ai/grok/ORCHESTRATOR.md"
  ];
  lifecycleForbiddenNeedles = [
    "review-start"
    "review-resume"
    "review-validate"
    "transaction locks"
    "Git-derived snapshots"
    "authoritative Engram receipts"
    "append-only CAS"
    "Lifecycle receipt rule"
    "gentle-ai review status"
  ];
  globalPolicyOnlyNeedles = [
    "## Engram Persistent Memory — Protocol"
    "Atlas task retrieval"
    "## Writing Comments, Docs, and External Messages — ALWAYS ACTIVE"
    "## CodeGraph"
  ];
  globalPolicyForbiddenNeedles = [
    "Memory & persistence"
    "## Local Policy"
    "## SDD Orchestrator Instructions"
    "### Work Routing"
    "### Intent & Irreversibility Gates"
    "SDD Workflow & Testing"
  ];
  orchestratorOwnedNeedles = [
    "## SDD Orchestrator"
    "## Intent & Irreversibility Gates"
    "### Explicit Review Protocols"
    "every question, option, default, consequence, and answer syntax"
    "Git mutation requires an explicit user request"
  ];
  orchestratorForbiddenNeedles = [
    "## SDD Workflow (Spec-Driven Development)"
    "### Artifact Store Policy"
    "### Commands"
    "### SDD Session Preflight (HARD GATE)"
    "### SDD Entry Routing (MANDATORY)"
    "### SDD Init Guard (MANDATORY)"
    "### Execution Mode"
    "### Automatic Mode Continuity (lightweight)"
    "### Artifact Store Mode"
    "### Dependency Graph"
    "### Status-Based Routing"
    "### Review Workload Forecast (report, never gate)"
    "### Engram Topic Key Format"
  ];
  automaticGitMutationNeedles = [
    "apply → sdd-verify(batch) → commit → report"
    "Commit per batch"
    "COMMIT that batch"
    "commit after every passing"
    "apply → verify → commit"
  ];
  inferredSddRoutingPatterns = [
    "[Ss]ubstantial changes.*SDD"
    "[Nn]ew feature.*SDD"
    "[Ww]ork spanning multiple files.*SDD"
    "[Rr]eal open design decisions.*SDD"
    "[Aa]utomatically enter SDD"
    "[Aa]utomatically route.*SDD"
  ];
  sddWorkflow = "ai/opencode/skills/_shared/sdd-orchestrator-workflow.md";
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
  fileDoesNotContainFixedString =
    relativePath: needle:
    let
      content = builtins.readFile (flakePath + "/" + relativePath);
    in
    builtins.replaceStrings [ needle ] [ "" ] content == content;
  fileIncludes =
    relativePath: needle:
    flake.inputs.nixpkgs.lib.hasInfix needle (builtins.readFile (flakePath + "/" + relativePath));
  fileDoesNotInclude = relativePath: needle: !(fileIncludes relativePath needle);
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
       resources = flake.inputs.nixpkgs.lib.imap0 (index: source: {
         inherit source;
         target = builtins.elemAt targets index;
       }) sources;
       canonicalResourceTargets = map (resource: resource.target) (builtins.filter (
         resource: builtins.match ".*-ai-harness/.*" resource.source != null
       ) resources);
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
         canonicalResourceTargets
         ;
       hasExpectedTargets = canonicalResourceTargets == expectedTargets;
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
       ) (renderedSecretTargets ++ mergedSecretTargets);
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
  resource: builtins.elem resource.classification [ "effective" "generated" "authoring-only" "local-adapter" "retired" ]
) matrixFamilies;
assert unique (map (resource: resource.name) matrixFamilies);
assert ownershipComplete matrixFamilies actualAiFamilies;
assert !(ownershipComplete removedAgensSkillsFixture actualAiFamilies);
assert !(ownershipComplete matrixFamilies addedUnclassifiedFamilyFixture);
assert agensCopyRoots == resourceMatrix.agensManagedRoots;
assert unique managedSourcePaths;
assert unique (map (resource: resource.target) managedResources);
assert builtins.all (
  resource: resource.classification == "retired" || assetExists "ai/${resource.source}"
) matrixFamilies;
assert builtins.all (target: !(builtins.elem target expectedTargets)) (renderedSecretTargets ++ mergedSecretTargets);
assert builtins.all (
  relativePath: fileIncludes relativePath "ai-harness-resources.nix"
) (map (path: "ai/${path}") resourceMatrix.providerParityReferences);
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
assert builtins.length sddCommandAssets == 14;
assert builtins.all (relativePath: builtins.all (needle: fileIncludes relativePath needle) [
  "agent: sdd-orchestrator"
  "Route"
]) sddCommandAssets;
assert builtins.all (
  relativePath: builtins.all (needle: fileDoesNotInclude relativePath needle) commandForbiddenNeedles
) sddCommandAssets;
assert assetExists sddStatusCommand;
assert builtins.all (needle: fileIncludes sddStatusCommand needle) [
  "agent: sdd-orchestrator"
  "Route"
  "status contract"
];
assert builtins.all (needle: fileDoesNotInclude sddStatusCommand needle) commandForbiddenNeedles;
assert builtins.all (needle: fileIncludes opencodeCoordinationWorkflow needle) opencodeWorkflowCoordinationNeedles;
assert builtins.all (
  needle: fileDoesNotContainFixedString opencodeCoordinationWorkflow needle
) opencodeWorkflowForbiddenNeedles;
assert fileIncludes onboardingFallbackOwner "every question, option, default, consequence, and answer syntax";
assert builtins.all (
  relativePath: fileDoesNotContain relativePath "every question, option, default, consequence, and answer syntax"
) onboardingFallbackConsumers;
assert builtins.all (needle: fileIncludes onboardingPrompt needle) [
  "validated preflight decision block"
  "Do not replace an injected value or infer a missing user choice"
];
assert builtins.all (needle: fileIncludes onboardingSkill needle) [
  "validated preflight decision block"
  "Do not replace or infer a choice"
];
assert !(opencodeConfig.agent.sdd-verify.tools ? edit);
assert !(opencodeConfig.agent.sdd-explore.tools ? edit);
assert opencodeConfig.agent.sdd-apply.tools.edit;
assert builtins.all (relativePath: !(assetExists relativePath)) retiredAssets;
assert builtins.all (
  authority:
  builtins.all (needle: fileDoesNotInclude authority needle) retiredAssetReferenceNeedles
) retiredAssetAuthorityAssets;
assert fileIncludes sddWorkflow sddPreflightContract;
assert fileDoesNotContain sddWorkflow "four localized groups";
assert builtins.all (
  relativePath:
  builtins.all (needle: fileContains relativePath needle) [
    "BLOCKER/CRITICAL IDs"
    "initial path set"
    "acceptance criteria"
    "regression evidence"
  ]
) judgmentDayLedgerAssets;
assert !(assetExists "ai/claude/agents/review-refuter.md");
assert builtins.all (
  relativePath:
  builtins.all (needle: fileDoesNotContainFixedString relativePath needle) claudeReviewOwnerForbiddenNeedles
) claudeReviewOwnerAssets;
assert builtins.all (
  relativePath: fileIncludes relativePath "only when the Judgment Day skill explicitly requests it"
) claudeJudgmentDayJudgeAssets;
assert builtins.all (
  relativePath:
  builtins.all (needle: fileContains relativePath needle) [
    "Judgment Day"
    "4R"
    "explicit"
  ]
) explicitReviewPolicyAssets;
assert builtins.all (check: builtins.all (needle: fileContains check.file needle) check.needles) [
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
      "Delivery Guarantee"
      "must never block"
    ];
  }
];
assert builtins.all (
  relativePath: builtins.all (needle: fileDoesNotContainFixedString relativePath needle) lifecycleForbiddenNeedles
) (effectiveNormalFlowAssets ++ [
  "ai/opencode/skills/judgment-day/SKILL.md"
  "ai/claude/skills/judgment-day/SKILL.md"
]);
assert builtins.all (
  relativePath: builtins.all (needle: fileDoesNotContainFixedString relativePath needle) contradictoryPolicyNeedles
) effectiveNormalFlowAssets;
assert builtins.all (
  relativePath: builtins.all (needle: fileDoesNotContainFixedString relativePath needle) normalFlowForbiddenNeedles
) effectiveNormalFlowAssets;
assert builtins.all (needle: fileContains "ai/opencode/AGENTS.md" needle) globalPolicyOnlyNeedles;
assert builtins.all (needle: fileDoesNotContain "ai/opencode/AGENTS.md" needle) globalPolicyForbiddenNeedles;
assert builtins.all (needle: fileContains "ai/opencode/ORCHESTRATOR.md" needle) orchestratorOwnedNeedles;
assert builtins.all (needle: fileDoesNotContain "ai/opencode/ORCHESTRATOR.md" needle) orchestratorForbiddenNeedles;
assert runRuntimeTests;
assert fileIncludes sddWorkflow "Explicit SDD entry";
assert fileIncludes sddWorkflow "apply → verify → report";
assert builtins.all (pattern: builtins.match (".*" + pattern + ".*") (builtins.readFile (flakePath + "/" + sddWorkflow)) == null) inferredSddRoutingPatterns;
assert builtins.all (
  relativePath: fileIncludes relativePath "explicit `strict_tdd: true` configuration"
) strictTddInitSkillAssets;
assert builtins.all (
  relativePath: fileDoesNotContain relativePath "Default `strict_tdd: true`"
) strictTddInitSkillAssets;
assert builtins.all (
  relativePath: fileIncludes relativePath "Strict TDD Applicability"
) strictTddInitReferenceAssets;
assert builtins.all (
  relativePath:
  fileIncludes relativePath "`strict_tdd: true` is explicitly configured"
  && fileIncludes relativePath "applicable behavioral test boundary"
) strictTddApplySkillAssets;
assert builtins.all (
  relativePath:
  fileIncludes relativePath "Explicit `strict_tdd: true` configuration"
  && fileIncludes relativePath "applicable behavioral test boundary"
) strictTddVerifySkillAssets;
assert builtins.all (
  relativePath:
  fileIncludes relativePath "Strict TDD is explicitly configured"
  && fileIncludes relativePath "applicable behavioral test boundary"
) strictTddTasksSkillAssets;
assert builtins.length strictTddForwardingCases == 8;
assert builtins.all (
  inputs: strictTddForwarded inputs == inputs.forwarded
) strictTddForwardingCases;
assert builtins.all (
  relativePath: fileIncludes relativePath "strict_tdd_configured, runner_available, and applicable_behavioral_boundary"
) strictTddForwardingAssets;
assert builtins.all (
  relativePath: fileDoesNotContainFixedString relativePath staleStrictTddActivationPhrase
) effectiveLazyWorkflowAssets;
assert builtins.all (
  relativePath: fileIncludes relativePath "Standard Verify always runs applicable test, build, and type checks."
) standardVerifyAssets;
assert builtins.all (
  relativePath: fileDoesNotInclude relativePath "Do NOT run tests unless `strict_tdd` is active"
) standardVerifyAssets;
assert builtins.all (
  relativePath: builtins.all (needle: fileDoesNotContainFixedString relativePath needle) [
    "write and commit code ONLY"
    "**One commit-set.**"
    "real commit and real file changes"
  ]
) strictTddApplySkillAssets;
assert flake.checks.x86_64-linux ? ai-harness-readiness;
assert builtins.all validState states;
assert builtins.all (name: assetExists "ai/skills/${name}/SKILL.md") grokSharedSkillNames;
assert grokProjectedAgentFiles == map (name: "${name}.md") grokProjectedAgentNames;
assert fileIncludes grokReadme "Grok Build discovers the shared `ai/skills` projection at `~/.agents/skills`.";
assert fileIncludes grokReadme "This harness does not project named `sdd-*` Grok agent profiles";
assert fileIncludes grokReadme "the projected `reviewer` profile";
assert fileIncludes grokOrchestrator "Shared `sdd-*` skills are direct skill mechanics, not Grok phase-agent definitions";
assert fileIncludes grokOrchestrator "only through the projected `reviewer` profile";
assert fileIncludes grokGlobalPolicy "configured `reviewer` profile";
assert fileDoesNotInclude grokGlobalPolicy "SDD phase agents when present";
{
  runtimeTest = ''
    set -eu

    source_tree=${flakePath}
    workdir="$(mktemp -d)"
    trap 'rm -rf "$workdir"' EXIT

    freshness_tree="$workdir/source"
    cp -r --no-preserve=mode,ownership "$source_tree" "$freshness_tree"
    chmod -R u+rwX "$freshness_tree"
    PATH=${flake.inputs.nixpkgs.legacyPackages.x86_64-linux.python3}/bin:$PATH \
      python3 -B "$freshness_tree/ai/agens/generate.py" --check

    require_no_automatic_git_mutation() {
      candidate="$1"

      ${flake.inputs.nixpkgs.lib.concatMapStringsSep "\n" (needle: ''
        if grep -F -- ${flake.inputs.nixpkgs.lib.escapeShellArg needle} "$candidate" >/dev/null; then
          echo "Automatic Git mutation contract reintroduced: ${needle}" >&2
          return 1
        fi
      '') automaticGitMutationNeedles}
    }

    require_explicit_sdd_routing() {
      candidate="$1"

      grep -F -- 'Enter SDD only when the user invokes `/sdd-*`, requests SDD in natural language, or accepts an offered SDD proposal.' "$candidate" >/dev/null
      grep -F -- 'Ordinary work remains direct.' "$candidate" >/dev/null

      ${flake.inputs.nixpkgs.lib.concatMapStringsSep "\n" (pattern: ''
        if grep -E -- ${flake.inputs.nixpkgs.lib.escapeShellArg pattern} "$candidate" >/dev/null; then
          echo "Inferred SDD routing contract reintroduced: ${pattern}" >&2
          return 1
        fi
      '') inferredSddRoutingPatterns}
    }

    require_no_normal_flow_policy() {
      candidate="$1"

      ${flake.inputs.nixpkgs.lib.concatMapStringsSep "\n" (needle: ''
        if grep -F -- ${flake.inputs.nixpkgs.lib.escapeShellArg needle} "$candidate" >/dev/null; then
          echo "Normal-flow policy reintroduced: ${needle}" >&2
          return 1
        fi
      '') normalFlowForbiddenNeedles}
    }

    assert_normal_flow_assets() {
      ${flake.inputs.nixpkgs.lib.concatMapStringsSep "\n" (relativePath: ''
        require_no_normal_flow_policy "$source_tree/${relativePath}"
      '') effectiveNormalFlowAssets}
    }

    assert_state_unchanged() {
      name="$1"
      repository="$2"
      before_status="$(git -C "$repository" status --porcelain=v1)"
      before_index="$(git -C "$repository" diff --cached --binary)"
      before_worktree="$(git -C "$repository" diff --binary)"

      require_no_automatic_git_mutation "$source_tree/ai/opencode/ORCHESTRATOR.md"
      require_no_automatic_git_mutation "$source_tree/${sddWorkflow}"
      require_explicit_sdd_routing "$source_tree/${sddWorkflow}"
      assert_normal_flow_assets

      test "$before_status" = "$(git -C "$repository" status --porcelain=v1)"
      test "$before_index" = "$(git -C "$repository" diff --cached --binary)"
      test "$before_worktree" = "$(git -C "$repository" diff --binary)"

      printf '%s\n' "$name verified"
    }

    initialize_repository() {
      repository="$1"

      git init -q "$repository"
      git -C "$repository" config user.email test@example.invalid
      git -C "$repository" config user.name "Projection Test"
      printf 'initial\n' > "$repository/tracked.txt"
      git -C "$repository" add tracked.txt
      git -C "$repository" commit -qm initial
    }

    staged_repository="$workdir/staged"
    initialize_repository "$staged_repository"
    printf 'staged\n' > "$staged_repository/tracked.txt"
    git -C "$staged_repository" add tracked.txt
    git -C "$staged_repository" diff --cached --quiet && exit 1
    assert_state_unchanged "staged changes" "$staged_repository"

    commit_a_repository="$workdir/commit-a"
    initialize_repository "$commit_a_repository"
    printf 'modified\n' > "$commit_a_repository/tracked.txt"
    git -C "$commit_a_repository" diff --quiet && exit 1
    git -C "$commit_a_repository" diff --cached --quiet
    assert_state_unchanged "commit -a eligible changes" "$commit_a_repository"

    empty_index_repository="$workdir/empty-index"
    initialize_repository "$empty_index_repository"
    git -C "$empty_index_repository" diff --quiet
    git -C "$empty_index_repository" diff --cached --quiet
    test -z "$(git -C "$empty_index_repository" status --porcelain=v1)"
    assert_state_unchanged "empty index" "$empty_index_repository"

    rejected_workflow="$workdir/inferred-routing.md"
    cp "$source_tree/${sddWorkflow}" "$rejected_workflow"
    chmod u+w "$rejected_workflow"
    printf '\nSubstantial changes automatically enter SDD.\n' >> "$rejected_workflow"
    if require_explicit_sdd_routing "$rejected_workflow"; then
      echo "Inferred SDD routing was not rejected." >&2
      exit 1
    fi

    rejected_policy="$workdir/reintroduced-policy.md"
    cp "$source_tree/ai/claude/skills/_shared/sdd-orchestrator-workflow.md" "$rejected_policy"
    chmod u+w "$rejected_policy"
    printf '\nautomatically launch a refuter\n' >> "$rejected_policy"
    if require_no_normal_flow_policy "$rejected_policy"; then
      echo "Reintroduced normal-flow policy was not rejected." >&2
      exit 1
    fi
  '';
  checkedHosts = hosts;
  inherit
    canonicalAssets
    expectedTargets
    expectedSecretEnv
    states
    ;
}
