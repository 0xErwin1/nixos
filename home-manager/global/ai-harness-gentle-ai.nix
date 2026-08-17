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
in
{
  imports = [ inputs.gentle-ai-nix.homeManagerModules.default ];

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
      ];

      paths = [
        ".config/opencode/opencode.json"
      ]
      ++ map (name: ".claude/mcp/${name}.json") (builtins.attrNames (serversFor "claude"));

      envFiles = [
        "${secretsDirectory}/mcp.env"
        "${secretsDirectory}/api.env"
      ];
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
    };
  };
}
