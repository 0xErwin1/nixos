# The Gentle AI harness, rendered by Gentle AI itself.
#
# What used to live here as a projection of a vendored copy of Gentle AI's
# assets is now asked for: the document below states the desired installation
# and `gentle-ai config render` produces the tree. A change to how Gentle AI
# renders arrives with the package instead of needing the vendored copy updated.
#
# What this module deliberately does not take over, and why:
#
#   - Anything carrying a secret. The MCP configuration for every client is
#     rendered at activation with tokens substituted from the secret env files,
#     which a Nix store path cannot hold. Those files stay on ai-harness.nix:
#     .claude.json, .codex/config.toml, .grok/config.toml, opencode.jsonc,
#     .pi/agent/mcp.json and the agens config.
#   - The Engram component, because it is what writes .codex/config.toml, and
#     that file must stay writable for the token substitution above.
#   - Providers Gentle AI has no adapter for: grok and agens.
#
# Everything the harness content is made of — agents, skills, commands, prompts
# and instructions for OpenCode, Claude Code and Codex — comes from the render.
{
  config,
  inputs,
  lib,
  ...
}:

let
  vendored = ../../ai;

  # Layered on top of the render rather than replacing it. `fill` copies only
  # what Gentle AI did not produce, so the agents, skills and commands that are
  # ours arrive while a stale copy of one Gentle AI also ships stays out of the
  # way. That is what lets this tree keep its own additions without pinning the
  # generated ones to whatever version it was last synced from.
  ownTree = target: source: {
    inherit target source;
    mode = "fill";
  };

  # Our own voice, added after everything Gentle AI generated. The persona is
  # declared custom so Gentle AI writes none of its own, and these carry ours.
  ownPolicy = target: source: {
    inherit target source;
    mode = "append";
  };
in
{
  imports = [ inputs.gentle-ai-nix.homeManagerModules.default ];

  programs.gentle-ai = {
    enable = true;

    providers = {
      opencode.enable = true;
      claude-code.enable = true;
      codex.enable = true;
    };

    components = {
      skills.enable = true;
      persona.enable = true;
      permissions.enable = true;
      sdd.enable = true;
      theme.enable = true;
    };

    # Our own persona lives in the appended policy below, so Gentle AI is told
    # to write none of its own rather than one being overwritten after the fact.
    persona = "custom";

    sdd = {
      mode = "multi";
      strictTdd = true;
    };

    # What ai/claude/settings-merge.json used to merge in at activation. The
    # deny list it also carried is exactly Gentle AI's own guardrails, which the
    # permissions component already writes.
    extensions.claude-code = {
      outputStyle = "Par";
      hooks.UserPromptSubmit = [
        {
          matcher = "";
          hooks = [
            {
              type = "command";
              command = "gentle-ai skill-registry refresh --quiet --no-gitignore --cwd \"\${CLAUDE_PROJECT_DIR:-$PWD}\" || true";
            }
          ];
        }
      ];
    };

    extraFiles = {
      # The Engram plugin comes with the component this module leaves out, so it
      # is layered from the vendored copy that ai-harness.nix used to project.
      opencode-engram-plugin = {
        target = ".config/opencode/plugins/engram.ts";
        source = "${vendored}/opencode/plugins/engram.ts";
      };

      opencode-agents = ownTree ".config/opencode/agent" "${vendored}/opencode/agent";
      opencode-commands = ownTree ".config/opencode/commands" "${vendored}/opencode/commands";
      opencode-prompts = ownTree ".config/opencode/prompts" "${vendored}/opencode/prompts";
      opencode-skills = ownTree ".config/opencode/skills" "${vendored}/opencode/skills";

      claude-agents = ownTree ".claude/agents" "${vendored}/claude/agents";
      claude-commands = ownTree ".claude/commands" "${vendored}/claude/commands";
      claude-skills = ownTree ".claude/skills" "${vendored}/claude/skills";
      claude-output-styles = ownTree ".claude/output-styles" "${vendored}/claude/output-styles";

      codex-agents = ownTree ".codex/agents" "${vendored}/codex/agents";
      codex-commands = ownTree ".codex/commands" "${vendored}/codex/commands";
      codex-skills = ownTree ".codex/skills" "${vendored}/codex/skills";

      opencode-policy = ownPolicy ".config/opencode/AGENTS.md" "${vendored}/opencode/AGENTS.md";
      claude-policy = ownPolicy ".claude/CLAUDE.md" "${vendored}/claude/CLAUDE.md";
      codex-policy = ownPolicy ".codex/AGENTS.md" "${vendored}/codex/AGENTS.md";
    };
  };

  # The rendered tree is what the readiness test inspects, so it is exposed
  # under a stable name rather than reached through the module's internals.
  home.sessionVariables.GENTLE_AI_RENDERED = "${config.programs.gentle-ai.rendered}/tree";

  assertions = [
    {
      assertion = !(lib.hasAttr "engram" config.programs.gentle-ai.components);
      message = "the engram component writes .codex/config.toml, which ai-harness.nix renders with secrets; leave it to that module";
    }
  ];
}
