let
  agensManagedRoots = builtins.fromJSON (builtins.readFile ../../ai/agens/managed-roots.json);
  agensCopyMetadata = {
    "AGENTS.md" = {
      name = "agens-instructions";
      target = ".config/agens/AGENTS.md";
    };
    agents = {
      name = "agens-agents";
      target = ".config/agens/agents";
    };
    commands = {
      name = "agens-commands";
      target = ".config/agens/commands";
    };
    skills = {
      name = "agens-skills";
      target = ".config/agens/skills";
    };
  };
  agensCopyFamilies = map (
    root:
    {
      inherit (agensCopyMetadata.${root}) name target;
      classification = "generated";
      delivery = "copy";
      source = "agens/${root}";
    }
    // (if root == "AGENTS.md" then { } else { recursive = true; })
  ) agensManagedRoots;
in
{
  inherit agensManagedRoots;
  requiredDeliveryFamilyNames = [
    "shared-skills"
    "opencode-instructions"
    "opencode-orchestrator"
    "opencode-agents"
    "opencode-commands"
    "shared-commands"
    "opencode-prompts"
    "opencode-skills"
    "opencode-tui"
    "opencode-plugins"
    "claude-instructions"
    "claude-orchestrator"
    "claude-engram-protocol"
    "claude-agents"
    "claude-commands"
    "claude-skills"
    "claude-output-styles"
    "codex-instructions"
    "codex-orchestrator"
    "codex-engram-instructions"
    "codex-engram-compact-prompt"
    "codex-commands"
    "codex-agents"
    "codex-skills"
    "codex-hooks"
    "codex-sdd-strong-profile"
    "codex-sdd-mid-profile"
    "codex-sdd-cheap-profile"
    "grok-instructions"
    "grok-orchestrator"
    "grok-agents"
    "agens-instructions"
    "agens-agents"
    "agens-commands"
    "agens-skills"
  ];
  # Every canonical harness family has one ownership classification. Runtime
  # targets are declared only here; consumers must derive their inventories.
  families = [
    {
      name = "shared-skills";
      classification = "effective";
      delivery = "project";
      source = "skills";
      target = ".agents/skills";
      recursive = true;
    }
    {
      name = "opencode-instructions";
      classification = "effective";
      delivery = "project";
      source = "opencode/AGENTS.md";
      target = ".config/opencode/AGENTS.md";
    }
    {
      name = "opencode-orchestrator";
      classification = "effective";
      delivery = "project";
      source = "opencode/ORCHESTRATOR.md";
      target = ".config/opencode/ORCHESTRATOR.md";
    }
    {
      name = "opencode-agents";
      classification = "effective";
      delivery = "project";
      source = "opencode/agent";
      target = ".config/opencode/agent";
      recursive = true;
    }
    {
      name = "opencode-commands";
      classification = "effective";
      delivery = "project";
      source = "opencode/commands";
      target = ".config/opencode/commands";
      recursive = true;
    }
    {
      name = "shared-commands";
      classification = "effective";
      delivery = "project";
      source = "command";
      target = ".config/opencode/command";
      recursive = true;
    }
    {
      name = "opencode-prompts";
      classification = "effective";
      delivery = "project";
      source = "opencode/prompts";
      target = ".config/opencode/prompts";
      recursive = true;
    }
    {
      name = "opencode-skills";
      classification = "effective";
      delivery = "project";
      source = "opencode/skills";
      target = ".config/opencode/skills";
      recursive = true;
    }
    {
      name = "opencode-tui";
      classification = "effective";
      delivery = "project";
      source = "opencode/tui.json";
      target = ".config/opencode/tui.json";
    }
    {
      name = "opencode-plugins";
      classification = "effective";
      delivery = "project";
      source = "opencode/plugins";
      target = ".config/opencode/plugins";
      recursive = true;
    }
    {
      name = "claude-instructions";
      classification = "effective";
      delivery = "project";
      source = "claude/CLAUDE.md";
      target = ".claude/CLAUDE.md";
    }
    {
      name = "claude-orchestrator";
      classification = "effective";
      delivery = "project";
      source = "claude/sdd-orchestrator.md";
      target = ".claude/sdd-orchestrator.md";
    }
    {
      name = "claude-engram-protocol";
      classification = "effective";
      delivery = "project";
      source = "claude/engram-protocol.md";
      target = ".claude/engram-protocol.md";
    }
    {
      name = "claude-agents";
      classification = "effective";
      delivery = "project";
      source = "claude/agents";
      target = ".claude/agents";
      recursive = true;
    }
    {
      name = "claude-commands";
      classification = "effective";
      delivery = "project";
      source = "claude/commands";
      target = ".claude/commands";
      recursive = true;
    }
    {
      name = "claude-skills";
      classification = "effective";
      delivery = "project";
      source = "claude/skills";
      target = ".claude/skills";
      recursive = true;
    }
    {
      name = "codex-instructions";
      classification = "effective";
      delivery = "project";
      source = "codex/AGENTS.md";
      target = ".codex/AGENTS.md";
    }
    {
      name = "codex-orchestrator";
      classification = "effective";
      delivery = "project";
      source = "codex/sdd-orchestrator.md";
      target = ".codex/sdd-orchestrator.md";
    }
    {
      name = "codex-engram-instructions";
      classification = "effective";
      delivery = "project";
      source = "codex/engram-instructions.md";
      target = ".codex/engram-instructions.md";
    }
    {
      name = "codex-engram-compact-prompt";
      classification = "effective";
      delivery = "project";
      source = "codex/engram-compact-prompt.md";
      target = ".codex/engram-compact-prompt.md";
    }
    {
      name = "codex-commands";
      classification = "effective";
      delivery = "project";
      source = "codex/commands";
      target = ".codex/commands";
      recursive = true;
    }
    {
      name = "codex-agents";
      classification = "effective";
      delivery = "project";
      source = "codex/agents";
      target = ".codex/agents";
      recursive = true;
    }
    {
      name = "claude-output-styles";
      classification = "effective";
      delivery = "project";
      source = "claude/output-styles";
      target = ".claude/output-styles";
      recursive = true;
    }
    {
      name = "codex-skills";
      classification = "effective";
      delivery = "project";
      source = "codex/skills";
      target = ".codex/skills";
      recursive = true;
    }
    {
      name = "codex-hooks";
      classification = "effective";
      delivery = "project";
      source = "codex/hooks.json";
      target = ".codex/hooks.json";
    }
    {
      name = "codex-sdd-strong-profile";
      classification = "effective";
      delivery = "project";
      source = "codex/sdd-strong.config.toml";
      target = ".codex/sdd-strong.config.toml";
    }
    {
      name = "codex-sdd-mid-profile";
      classification = "effective";
      delivery = "project";
      source = "codex/sdd-mid.config.toml";
      target = ".codex/sdd-mid.config.toml";
    }
    {
      name = "codex-sdd-cheap-profile";
      classification = "effective";
      delivery = "project";
      source = "codex/sdd-cheap.config.toml";
      target = ".codex/sdd-cheap.config.toml";
    }
    {
      name = "grok-instructions";
      classification = "local-adapter";
      delivery = "project";
      source = "grok/AGENTS.md";
      target = ".grok/AGENTS.md";
    }
    {
      name = "grok-orchestrator";
      classification = "local-adapter";
      delivery = "project";
      source = "grok/ORCHESTRATOR.md";
      target = ".grok/ORCHESTRATOR.md";
    }
    {
      name = "grok-agents";
      classification = "local-adapter";
      delivery = "project";
      source = "grok/agents";
      target = ".grok/agents";
      recursive = true;
    }
  ] ++ agensCopyFamilies ++ [
    {
      name = "opencode-runtime-config";
      classification = "effective";
      delivery = "render";
      source = "opencode/opencode.jsonc";
      target = ".config/opencode/opencode.jsonc";
    }
    {
      name = "pi-runtime-config";
      classification = "effective";
      delivery = "render";
      source = "pi/mcp.json";
      target = ".pi/agent/mcp.json";
    }
    {
      name = "claude-runtime-mcp";
      classification = "effective";
      delivery = "merge";
      kind = "json-mcpservers";
      source = "claude/mcp-servers.json";
      target = ".claude.json";
    }
    {
      name = "codex-runtime-mcp";
      classification = "effective";
      delivery = "merge";
      kind = "toml-mcpservers";
      source = "codex/mcp-servers.toml";
      target = ".codex/config.toml";
    }
    {
      name = "grok-runtime-mcp";
      classification = "local-adapter";
      delivery = "merge";
      kind = "toml-mcpservers";
      source = "grok/mcp-servers.toml";
      target = ".grok/config.toml";
    }
    {
      name = "claude-runtime-settings";
      classification = "effective";
      delivery = "merge";
      kind = "json-deep-merge";
      source = "claude/settings-merge.json";
      target = ".claude/settings.json";
    }
    {
      name = "agens-runtime-config";
      classification = "local-adapter";
      delivery = "merge";
      kind = "toml-mcp-permissions";
      source = "agens/config.toml";
      target = ".config/agens/config.toml";
    }
    {
      name = "shared-contracts";
      classification = "authoring-only";
      source = "shared";
    }
    {
      name = "harness-support";
      classification = "authoring-only";
      source = "support";
    }
    {
      name = "agens-generator";
      classification = "authoring-only";
      source = "agens/generate.py";
    }
    {
      name = "agens-generation-guide";
      classification = "authoring-only";
      source = "agens/README.md";
    }
    {
      name = "retired-root-commands";
      classification = "retired";
      source = "commands";
      paths = [
        "commands/sdd-apply.md"
        "commands/sdd-archive.md"
        "commands/sdd-continue.md"
        "commands/sdd-explore.md"
        "commands/sdd-ff.md"
        "commands/sdd-init.md"
        "commands/sdd-new.md"
        "commands/sdd-onboard.md"
        "commands/sdd-verify.md"
      ];
    }
    {
      name = "retired-opencode-overlays";
      classification = "retired";
      source = "opencode/sdd-overlay-single.json";
      paths = [ "opencode/sdd-overlay-single.json" ];
    }
    {
      name = "retired-opencode-multi-overlays";
      classification = "retired";
      source = "opencode/sdd-overlay-multi.json";
      paths = [ "opencode/sdd-overlay-multi.json" ];
    }
    {
      name = "retired-nested-skill-improver";
      classification = "retired";
      source = "skills/skill-improver/skill-improver";
      paths = [
        "skills/skill-improver/skill-improver/SKILL.md"
        "skills/skill-improver/skill-improver/references/skill-style-guide.md"
        "agens/skills/skill-improver/skill-improver/SKILL.md"
        "agens/skills/skill-improver/skill-improver/references/skill-style-guide.md"
      ];
    }
  ];

  providerParityReferences = [
    "skills/upstream-ai-sync/references/provider-parity.md"
    "claude/skills/upstream-ai-sync/references/provider-parity.md"
    "codex/skills/upstream-ai-sync/references/provider-parity.md"
  ];
}
