# The AI harness, rendered by Gentle AI itself.
#
# The desired installation is declared here and `gentle-ai config render`
# produces the tree, so a change to how Gentle AI renders arrives with the
# package rather than needing a vendored copy re-synced.
#
# Clients Gentle AI has no adapter for -- grok and agens -- receive the harness
# another client produced. Files carrying a credential are written at
# activation, and the two the client also writes are merged into rather than
# replaced, because they hold state Claude Code and Codex own themselves.
{
  config,
  inputs,
  lib,
  ...
}:

let
  vendored = ../../ai;

  # ai/custom holds what is ours and nothing else. Layered as fill so that if
  # Gentle AI ever ships something at one of these paths, its version wins and
  # the duplicate here becomes visible as dead weight rather than silently
  # overriding an upstream change.
  ownTree = target: provider: {
    inherit target;
    source = "${vendored}/custom/${provider}";
    mode = "fill";
  };

  # A contract of ours at a path Gentle AI does not render, so it is the whole
  # content there rather than a layer over generated content.
  own = target: path: {
    inherit target;
    source = "${vendored}/${path}";
  };

  # Our rules and persona, with the blocks Gentle AI regenerates taken out.
  ownPolicy = target: provider: {
    inherit target;
    source = "${vendored}/custom/policy/${provider}.md";
    mode = "append";
  };

  secretsDirectory = "${config.home.homeDirectory}/.config/ai-harness/secrets";

  remote = url: headers: { inherit url headers; };
  local = command: args: { inherit command args; };

  # Every client gets these. The token placeholders resolve at activation from
  # the secret env files below, so nothing here reaches the Nix store as a
  # credential.
  sharedServers = {
    atlas = remote "https://atlas.iperez.dev/mcp" {
      Authorization = "Bearer @ATLAS_TOKEN@";
    };
    context7 = remote "https://mcp.context7.com/mcp" {
      CONTEXT7_API_KEY = "@CONTEXT7_API_KEY@";
    };
    penpot = remote "https://penpot.iperez.dev/mcp/stream?userToken=@PENPOT_API_KEY@" { };

    aws = (local "uvx" [ "awslabs.aws-documentation-mcp-server@latest" ]) // {
      env = {
        AWS_DOCUMENTATION_PARTITION = "aws";
        FASTMCP_LOG_LEVEL = "ERROR";
      };
    };
    maestro = local "maestro" [ "mcp" ];
    obsidian = local "pnpx" [
      "@mauricio.wolff/mcp-obsidian@latest"
      "${config.home.homeDirectory}/Atlas"
    ];
    clickup = local "npx" [
      "-y"
      "mcp-remote"
      "https://mcp.clickup.com/mcp"
    ];
  };

  # dbflux is told which client connected, so it is the one server that cannot
  # be shared: each client names itself.
  serversFor =
    client:
    sharedServers
    // {
      dbflux = local "dbflux" [
        "mcp"
        "--client-id"
        client
      ];
    };

  secretEnvFiles = [
    "${secretsDirectory}/mcp.env"
    "${secretsDirectory}/api.env"
  ];
in
{
  imports = [ inputs.gentle-ai-nix.homeManagerModules.default ];

  # A missing env file leaves every placeholder unresolved rather than emptied,
  # so nothing is destroyed, but the result is a harness whose servers cannot
  # authenticate and say nothing about why. Refusing before the write boundary
  # is the point at which that is still one message instead of a debugging
  # session.
  home.activation.gentleAiSecretsPreflight = lib.hm.dag.entryBefore [ "writeBoundary" ] ''
    for secret_env_file in ${lib.escapeShellArgs secretEnvFiles}; do
      if [ ! -f "$secret_env_file" ]; then
        echo "AI harness required env file is missing: $secret_env_file" >&2
        echo "Create it locally with mode 600 before switching; never commit token values." >&2
        exit 1
      fi
    done
  '';

  programs.gentle-ai = {
    enable = true;

    providers = {
      opencode = {
        enable = true;
        mcpServers = serversFor "opencode";
      };

      claude-code.enable = true;

      codex = {
        enable = true;
        mcpServers = serversFor "codex";
      };

      # Pi keeps its harness in packages its own tool installs rather than in
      # files, so rendering produces the configuration around it and activation
      # runs the installation Gentle AI declares for it.
      pi = {
        enable = true;
        mcpServers = serversFor "pi";
        provisionPackages = true;
      };
    };

    components = {
      skills.enable = true;
      persona.enable = true;
      permissions.enable = true;
      sdd.enable = true;
      theme.enable = true;
      engram.enable = true;
    };

    # Our own persona is appended below, so Gentle AI writes none of its own.
    persona = "custom";

    sdd = {
      mode = "multi";
      strictTdd = true;
    };

    # Both clients that express it run their sub-agents in the background,
    # which is what the orchestration policy in their prompts is written for.
    backgroundSubagents = {
      opencode = "on";
      pi = "on";
    };

    mcpServers = serversFor "claude";

    # Every path here holds a credential once the placeholders resolve, so none
    # can be a store symlink. The first two are shared with the client itself --
    # Claude Code keeps its OAuth session and project history in .claude.json,
    # Codex its per-project trust levels in config.toml -- so they are merged
    # into rather than replaced.
    secrets = {
      merge = [
        ".claude.json"
        ".claude/settings.json"
        ".codex/config.toml"

        # Pi writes its own model, provider, theme and changelog state here, and
        # npm rewrites the package file, so both are merged into rather than
        # replaced even though neither carries a credential.
        ".pi/agent/settings.json"
        ".pi/npm/package.json"
      ];

      paths = [
        ".config/opencode/opencode.json"
        ".pi/agent/mcp.json"
      ]
      ++ map (name: ".claude/mcp/${name}.json") (builtins.attrNames (serversFor "claude"));

      envFiles = secretEnvFiles;
    };

    # Neither has a Gentle AI adapter, and both read the same kind of harness.
    # Agens takes copies because its loader opens agents and skills with
    # O_NOFOLLOW and rejects anything reached through a symbolic link.
    customProviders = {
      # Grok reads agents from `agents/`, where OpenCode uses `agent/`, so the
      # directory is renamed on the way rather than the harness being rebuilt
      # for it.
      grok = {
        root = ".grok";
        from = "opencode";
        assets = {
          agent = "agents";
          commands = "commands";
          skills = "skills";
        };
      };

      agens = {
        root = ".config/agens";
        from = "claude-code";
        delivery = "copy";
        assets = {
          "CLAUDE.md" = "AGENTS.md";
          agents = "agents";
          commands = "commands";
          skills = "skills";
        };
      };
    };

    # What ai/claude/settings-merge.json used to merge in at activation. The
    # deny list it also carried is exactly Gentle AI's own guardrails, which the
    # permissions component already writes.
    # Settings this configuration owns. Claude Code writes into the same file --
    # a theme picked in the UI lands there -- which is why it is merged rather
    # than replaced below.
    extensions.claude-code = {
      outputStyle = "Par";
      "model" = "opus[1m]";
      "workflowKeywordTriggerEnabled" = false;
      "statusLine" = {
        "type" = "command";
        "command" = "ccstatusline";
        "padding" = 0;
        "refreshInterval" = 10;
      };
      "enabledPlugins" = {
        "figma@claude-plugins-official" = true;
        "rust-analyzer-lsp@claude-plugins-official" = false;
        "warp@claude-code-warp" = true;
        "engram@engram" = true;
      };
      "extraKnownMarketplaces" = {
        "claude-code-plugins" = {
          "source" = {
            "source" = "github";
            "repo" = "anthropics/claude-code";
          };
        };
        "claude-plugins-official" = {
          "source" = {
            "source" = "github";
            "repo" = "anthropics/claude-plugins-official";
          };
        };
        "claude-code-warp" = {
          "source" = {
            "source" = "github";
            "repo" = "warpdotdev/claude-code-warp";
          };
        };
        "engram" = {
          "source" = {
            "source" = "github";
            "repo" = "Gentleman-Programming/engram";
          };
        };
      };
      "effortLevel" = "medium";
      "tui" = "fullscreen";
      "skipDangerousModePermissionPrompt" = true;
      "theme" = "dark-daltonized";
      "editorMode" = "vim";
      "agentPushNotifEnabled" = true;

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
      # The Engram plugin ships with Engram itself rather than with Gentle AI,
      # so it is layered from the copy this repository vendors.
      opencode-engram-plugin = {
        target = ".config/opencode/plugins/engram.ts";
        source = "${vendored}/custom/opencode/plugins/engram.ts";
      };

      grok-own = ownTree ".grok" "grok";

      opencode-own = ownTree ".config/opencode" "opencode";
      claude-own = ownTree ".claude" "claude";
      codex-own = ownTree ".codex" "codex";

      opencode-policy = ownPolicy ".config/opencode/AGENTS.md" "opencode";
      claude-policy = ownPolicy ".claude/CLAUDE.md" "claude";
      codex-policy = ownPolicy ".codex/AGENTS.md" "codex";

      # Contracts of our own at paths Gentle AI does not render. They used to
      # reach these targets through the Pi harness module, which projected files
      # for every client and not only for Pi; they are declared here now that
      # the module is gone.
      shared-skills = own ".agents/skills" "skills";

      opencode-orchestrator = own ".config/opencode/ORCHESTRATOR.md" "opencode/ORCHESTRATOR.md";
      opencode-commands = own ".config/opencode/command" "command";
      opencode-tui = own ".config/opencode/tui.json" "opencode/tui.json";

      claude-orchestrator = own ".claude/sdd-orchestrator.md" "claude/sdd-orchestrator.md";
      claude-engram-protocol = own ".claude/engram-protocol.md" "claude/engram-protocol.md";

      codex-orchestrator = own ".codex/sdd-orchestrator.md" "codex/sdd-orchestrator.md";
      codex-engram-instructions = own ".codex/engram-instructions.md" "codex/engram-instructions.md";
      codex-engram-compact-prompt = own ".codex/engram-compact-prompt.md" "codex/engram-compact-prompt.md";
      codex-sdd-strong = own ".codex/sdd-strong.config.toml" "codex/sdd-strong.config.toml";
      codex-sdd-mid = own ".codex/sdd-mid.config.toml" "codex/sdd-mid.config.toml";
      codex-sdd-cheap = own ".codex/sdd-cheap.config.toml" "codex/sdd-cheap.config.toml";
    };
  };
}
