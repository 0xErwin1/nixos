{
  requiredDeliveryFamilyNames = [
    "shared-skills"
    "opencode-orchestrator"
    "shared-commands"
    "opencode-tui"
    "claude-orchestrator"
    "claude-engram-protocol"
    "codex-orchestrator"
    "codex-engram-instructions"
    "codex-engram-compact-prompt"
    "codex-sdd-strong-profile"
    "codex-sdd-mid-profile"
    "codex-sdd-cheap-profile"
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
      name = "opencode-orchestrator";
      classification = "effective";
      delivery = "project";
      source = "opencode/ORCHESTRATOR.md";
      target = ".config/opencode/ORCHESTRATOR.md";
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
      name = "opencode-tui";
      classification = "effective";
      delivery = "project";
      source = "opencode/tui.json";
      target = ".config/opencode/tui.json";
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
  ] ++ [
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
  ];

  providerParityReferences = [
    "skills/upstream-ai-sync/references/provider-parity.md"
    "claude/skills/upstream-ai-sync/references/provider-parity.md"
    "codex/skills/upstream-ai-sync/references/provider-parity.md"
  ];
}
