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

  # ai/custom holds what is ours and nothing else: the agents, commands,
  # prompts and skills Gentle AI does not ship. Keeping it a separate tree is
  # what makes the boundary a stated fact rather than the outcome of a
  # collision, and it is why a copy of a file Gentle AI also ships can no longer
  # end up shadowing the current one -- there are none in here to shadow with.
  #
  # Layered as fill so that if Gentle AI ever starts shipping something at one
  # of these paths, its version wins and the duplicate here becomes visible as
  # dead weight rather than silently overriding an upstream change.
  ownTree = target: provider: {
    inherit target;
    source = "${vendored}/custom/${provider}";
    mode = "fill";
  };

  # ai/custom/policy holds our rules and persona with the two blocks Gentle AI
  # regenerates under this document -- sdd-orchestrator and strict-tdd-mode --
  # taken out. Appending the vendored file whole instead would land both copies
  # of everything Gentle AI writes.
  #
  # Our persona lives in these files rather than in Gentle AI's persona slot
  # because the slot was where it always lived: the component is told to write
  # none of its own, and this supplies it.
  ownPolicy = target: provider: {
    inherit target;
    source = "${vendored}/custom/policy/${provider}.md";
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

      opencode-own = ownTree ".config/opencode" "opencode";
      claude-own = ownTree ".claude" "claude";
      codex-own = ownTree ".codex" "codex";

      opencode-policy = ownPolicy ".config/opencode/AGENTS.md" "opencode";
      claude-policy = ownPolicy ".claude/CLAUDE.md" "claude";
      codex-policy = ownPolicy ".codex/AGENTS.md" "codex";
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
