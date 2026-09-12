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
  pkgs,
  ...
}:

let
  vendored = ../../ai;

  /*
      Disabled custom whole-provider overlay. Retain the source assets for possible
      future re-enablement, but let Gentle AI own agents, policies, commands, and
      plugins. The active overlays below are limited to local skills.
    ownTree = target: provider: {
      inherit target;
      source = "${vendored}/custom/${provider}";
      mode = "fill";
    };
  */

  # A contract of ours at a path Gentle AI does not render, so it is the whole
  # content there rather than a layer over generated content.
  own = target: path: {
    inherit target;
    source = "${vendored}/${path}";
  };

  /*
      Disabled local policy and persona append helpers. The upstream policy and
      persona component remain active without an appended local suffix.
    ownPolicy = target: provider: {
      inherit target;
      source = "${vendored}/custom/policy/${provider}.md";
      mode = "append";
    };

    parPersonaBody = pkgs.runCommandLocal "par-persona-body" { } ''
      sed '1,/^---$/d' ${vendored}/custom/claude/output-styles/Par.md > "$out"
    '';

    parPersona = target: {
      inherit target;
      source = parPersonaBody;
      mode = "append";
    };
  */

  secretsDirectory = "${config.home.homeDirectory}/.config/ai-harness/secrets";

  /*
    Disabled Herdr integration helpers and registrations.
    integrations = pkgs.agent-integrations { inherit (config.home) homeDirectory; };

    registered = target: source: {
      inherit target;
      source = "${integrations}/${source}";
    };

    claudeHookEvents = [
      "PermissionRequest"
      "PostToolUse"
      "PreToolUse"
      "SessionEnd"
      "SessionStart"
      "Stop"
      "UserPromptSubmit"
    ];

    codexHookEvents = [
      "PermissionRequest"
      "SessionStart"
      "Stop"
      "UserPromptSubmit"
    ];
  */

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
      dbflux = local "dbflux-nightly" [
        "mcp"
        "--client-id"
        client
      ];
    };

  # The work profile starts from the rendered personal settings, but it cannot
  # take them as a store symlink because Claude Code writes its own session state
  # into that file. Copying it into the tree makes it a merge target like the
  # personal profile, preserving mutable state without adding local preferences.
  withWorkSettings =
    tree:
    pkgs.runCommandLocal "gentle-ai-config-with-work-settings" { } ''
      # Modes stay: the tree carries executables such as the Pi engram plugin's
      # entry point, and dropping them here is what a permission denied at
      # activation looks like.
      cp -r --no-preserve=ownership ${tree} "$out"
      chmod -R u+w "$out"
      mkdir -p "$out/tree/.claude-work"
      cp "$out/tree/.claude/settings.json" "$out/tree/.claude-work/settings.json"
    '';

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

    # Gentle AI's beta channel is the tip of main, not a release candidate, and
    # the build this harness renders through is main with the declarative
    # configuration contract on top. Declaring it keeps the recorded channel and
    # the installed build saying the same thing.
    install.channel = "beta";

    providers = {
      opencode = {
        enable = true;
        mcpServers = serversFor "opencode";
      };

      claude-code = {
        enable = true;
        settings = {
          model = "opus[1m]";
          workflowKeywordTriggerEnabled = false;
          statusLine = {
            type = "command";
            command = "ccstatusline";
            padding = 0;
            refreshInterval = 10;
          };
          attribution = {
            commit = "";
            pr = "";
            sessionUrl = false;
          };
          enabledPlugins = {
            "figma@claude-plugins-official" = true;
            "rust-analyzer-lsp@claude-plugins-official" = false;
            "warp@claude-code-warp" = true;
            "engram@engram" = true;
          };
          extraKnownMarketplaces = {
            claude-code-plugins = {
              source = {
                source = "github";
                repo = "anthropics/claude-code";
              };
            };
            claude-plugins-official = {
              source = {
                source = "github";
                repo = "anthropics/claude-plugins-official";
              };
            };
            engram = {
              source = {
                source = "github";
                repo = "Gentleman-Programming/engram";
              };
            };
          };
          effortLevel = "medium";
          tui = "fullscreen";
          skipDangerousModePermissionPrompt = true;
          theme = "dark-daltonized";
          editorMode = "vim";
          agentPushNotifEnabled = true;
          env = {
            DISABLE_AUTOUPDATER = "1";
            CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS = "1";
          };
        };
      };

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
        packages = {
          "@gtrabanco/pi-nan-provider" = "npm:@gtrabanco/pi-nan-provider";
        };
        provisionPackages = true;

        # The install commands name packages without naming versions, so their
        # text never changes while what npm resolves them to does. Stamped by
        # that text they run once, which froze gentle-pi at the version the
        # first activation happened to install.
        provisionRefresh = true;

        # gentle-pi's postinstall downloads its private, package-pinned Gentle AI
        # binary and extracts it with /usr/bin/tar or /bin/tar by absolute path.
        # NixOS lacks those host paths, so normal provisioning defers that lifecycle
        # to the compatibility repair below; the global CLI is not an equivalent.
        provisionEnvironment.GENTLE_PI_SKIP_GENTLE_AI_INSTALL = "1";
        settings.theme = "Gentle";
        modelPreset = "recommended";
        modelFamily = "codex";
        # gentle-pi agent profiles carry the whole routing: the orchestrator Pi
        # itself runs on and the model each phase agent gets. Naming one active
        # is the declarative form of applying it in /gentle:profiles, so a
        # switch is what a profile change takes. An agent a profile does not
        # name inherits whatever routing is in force outside the profile.
        profiles =
          let
            on = model: effort: {
              provider = "openai-codex";
              inherit model effort;
            };
            sol = on "gpt-5.6-sol";
            luna = on "gpt-5.6-luna";
            terra = on "gpt-5.6-terra";
            astra = on "gpt-6-astra";
          in
          {
            codex = {
              orchestrator = astra "high";
              phases = {
                jd-judge-a = astra "low";
                jd-judge-b = astra "low";
                sdd-design = astra "low";
                sdd-proposal = astra "low";
                sdd-init = luna "low";
                sdd-status = luna "low";
                sdd-sync = luna "low";
                sdd-explore = terra "medium";
                sdd-research = terra "medium";
                sdd-verify = terra "medium";
                sdd-spec = terra "high";
                sdd-tasks = terra "high";
                gentle-ai-explore = terra "high";
                gentle-ai-verify = terra "high";
                gentle-ai-worker = terra "medium";
              };
            };

            # Heavier phases on terra at high effort, judgment and review on
            # astra at low; sdd-research is left out on purpose so it inherits.
            performance = {
              orchestrator = astra "high";
              phases = {
                sdd-init = sol "medium";
                sdd-onboard = sol "medium";
                sdd-status = sol "medium";
                sdd-sync = sol "medium";
                sdd-explore = terra "high";
                sdd-spec = terra "high";
                sdd-tasks = terra "high";
                sdd-apply = terra "high";
                sdd-archive = luna "high";
                sdd-proposal = astra "low";
                sdd-design = astra "low";
                sdd-verify = astra "low";
                jd-judge-a = astra "low";
                jd-judge-b = astra "low";
                jd-fix-agent = terra "high";
                gentle-ai-explore = terra "high";
                gentle-ai-verify = astra "low";
                gentle-ai-worker = terra "high";
                review-readability = astra "low";
                review-refuter = astra "low";
                review-reliability = astra "low";
                review-resilience = astra "low";
                review-risk = astra "low";
                review-validator = astra "low";
              };
            };
          };
        activeProfile = "performance";
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

    communityTools.codegraph.enable = true;
    persona = "neutral";

    sdd = {
      mode = "multi";
      strictTdd = true;
    };

    review.mode = "on";

    # gentle-pi from the tip of its main branch, pinned by gentle-ai-nix, and
    # Engram's release candidate for both the binary and Pi's plugin.
    gentlePiRelease = "main";
    engramRelease = "rc";

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
        ".claude-work/settings.json"
        ".codex/config.toml"

        # Pi writes its own model, provider and changelog state here, and npm
        # rewrites the package file, so both are merged into rather than
        # replaced even though neither carries a credential. The package list is
        # Pi's own: it rebuilds it as it installs, so it accumulates instead of
        # being cut back to the one entry the document names.
        {
          path = ".pi/agent/settings.json";
          unionLists = [ "packages" ];
        }
        ".pi/npm/package.json"

        # Gentle AI never renders Pi's engram configuration: its adapter
        # short-circuits the shared injection and defers mcp.json to
        # `pi-engram init`, which activation runs as a provisioning command.
        # Replacing the file here would drop the entry that step wrote, so the
        # declared servers merge into it instead.
        ".pi/agent/mcp.json"
      ];

      paths = [
        ".config/opencode/opencode.json"
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
          "AGENTS.md" = "AGENTS.md";
          agent = "agents";
          commands = "commands";
          skills = "skills";
        };
      };

      # The work profile is Claude Code with its own config directory. It shares
      # the harness -- same agents, skills, commands and policy -- and keeps its
      # own MCP set and its own session state, which is why those two are not
      # listed here and stay whatever that directory already holds.
      claude-work = {
        root = ".claude-work";
        from = "claude-code";
        assets = {
          "CLAUDE.md" = "CLAUDE.md";
          agents = "agents";
          commands = "commands";
          skills = "skills";
          output-styles = "output-styles";

          # Upstream embeds these contracts in CLAUDE.md/settings.json rather
          # than rendering separate files; mapping them would create broken links.
          # hooks = "hooks";
          # "sdd-orchestrator.md" = "sdd-orchestrator.md";
          # "engram-protocol.md" = "engram-protocol.md";
        };
      };

      agens = {
        root = ".config/agens";
        from = "claude-code";
        delivery = "copy";

        # Agens requires `mode:` in every agent definition and skips one that
        # lacks it, silently, into discovery diagnostics -- the Claude Code
        # dialect these files arrive in has no such field. Filled only where
        # missing, so a definition that states its own mode keeps it.
        frontmatterDefaults.agents.mode = "subagent";

        # The copies arrive readable, but the harness cross-references itself by
        # path, and those paths named .claude. Every one of them resolves to a
        # store symlink, which is the shape agens refuses, so it was being sent
        # to files it cannot open while holding a readable copy of each one.
        rewriteReferences = true;

        assets = {
          "CLAUDE.md" = "AGENTS.md";
          agents = "agents";
          commands = "commands";
          skills = "skills";
        };
      };
    };

    # Preserve the writable work-profile settings merge for client-owned state.
    overrideRendered = withWorkSettings;

    extraFiles = {
      /*
        Disabled custom Engram plugin; the engram component renders upstream
           integration and protocol defaults.
        opencode-engram-plugin = {
          target = ".config/opencode/plugins/engram.ts";
          source = "${vendored}/custom/opencode/plugins/engram.ts";
        };
      */

      /*
        Disabled custom whole-provider overlays.
        grok-own = ownTree ".grok" "grok";
        opencode-own = ownTree ".config/opencode" "opencode";
        claude-own = ownTree ".claude" "claude";
        codex-own = ownTree ".codex" "codex";
      */

      /*
        Disabled custom policy append projections.
        opencode-policy = ownPolicy ".config/opencode/AGENTS.md" "opencode";
        claude-policy = ownPolicy ".claude/CLAUDE.md" "claude";
        codex-policy = ownPolicy ".codex/AGENTS.md" "codex";
      */

      # Agens borrows Claude's post-overlay CLAUDE.md, while Grok owns AGENTS.md
      # outside its borrowed assets. Pi and Grok receive the compact local appendix
      # before Par, which must remain the exact suffix for each delivered policy.
      /*
        Disabled local Pi/Grok policy and Par persona projections. Grok now maps
           the upstream OpenCode AGENTS.md through customProviders.
        pi-local-policy = ownPolicy ".pi/agent/AGENTS.md" "pi-grok";
        grok-policy = ownPolicy ".grok/AGENTS.md" "pi-grok";
        pi-shared-par-persona = parPersona ".pi/agent/AGENTS.md";
        opencode-shared-par-persona = parPersona ".config/opencode/AGENTS.md";
        codex-shared-par-persona = parPersona ".codex/AGENTS.md";
        grok-shared-par-persona = parPersona ".grok/AGENTS.md";
        claude-shared-par-persona = parPersona ".claude/CLAUDE.md";
      */

      # Keep locally authored skills as narrow fill overlays; upstream owns every
      # non-skill asset at these roots.
      opencode-custom-skills = {
        target = ".config/opencode/skills";
        source = "${vendored}/custom/opencode/skills";
        mode = "fill";
      };
      claude-custom-skills = {
        target = ".claude/skills";
        source = "${vendored}/custom/claude/skills";
        mode = "fill";
      };
      codex-custom-skills = {
        target = ".codex/skills";
        source = "${vendored}/custom/codex/skills";
        mode = "fill";
      };

      # Shared skills are outside a provider root and remain managed directly.
      shared-skills = own ".agents/skills" "skills";

      /*
        Disabled custom orchestration, commands, TUI, Engram protocol/config,
           hooks, plugins, and Herdr registrations.
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

        herdr-claude-hooks = {
          target = ".claude/settings.json";
          source = "${integrations}/.claude/settings.json";
          mode = "merge";
          unionLists = map (event: "hooks.${event}") claudeHookEvents;
        };

        herdr-codex-feature = {
          target = ".codex/config.toml";
          source = "${integrations}/.codex/config.toml";
          mode = "merge";
        };

        # Codex keeps its hooks in a file of their own, but Gentle AI writes its
        # skill-registry hook into that same file, so this merges too.
        herdr-codex-hooks = {
          target = ".codex/hooks.json";
          source = "${integrations}/.codex/hooks.json";
          mode = "merge";
          unionLists = map (event: "hooks.${event}") codexHookEvents;
        };

        herdr-claude-hook = registered ".claude/hooks/herdr-agent-state.sh" ".claude/hooks/herdr-agent-state.sh";
        herdr-codex-hook = registered ".codex/herdr-agent-state.sh" ".codex/herdr-agent-state.sh";

        herdr-opencode-plugin = registered ".config/opencode/plugins/herdr-agent-state.js" ".config/opencode/plugins/herdr-agent-state.js";
        herdr-pi-extension = registered ".pi/agent/extensions/herdr-agent-state.ts" ".pi/agent/extensions/herdr-agent-state.ts";
      */
    };
  };

  # Provisioning keeps its skip because a fresh gentle-pi install otherwise
  # reaches an absolute host tar path that NixOS does not provide. Once that
  # package exists, rerun only its original lifecycle in a private FHS that
  # supplies /usr/bin/tar. Its installer retains the signed integrity decision
  # and is a no-op when the bundled Gentle AI is already valid.
  # gentle-pi's postinstall needs the FHS tar paths, wherever the package
  # landed: the npm prefix for the stable channel, the git checkout for main.
  home.activation.gentlePiRuntimeRepair = lib.hm.dag.entryAfter [ "gentleAiProvisionPackages" ] ''
    run ${lib.getExe pkgs.gentle-pi-runtime-repair} --prefix ${lib.escapeShellArg "${config.home.homeDirectory}/.pi/agent/npm"}
    run ${lib.getExe pkgs.gentle-pi-runtime-repair} --package-dir ${lib.escapeShellArg "${config.home.homeDirectory}/.pi/agent/git/github.com/Gentleman-Programming/gentle-pi"}
  '';
}
