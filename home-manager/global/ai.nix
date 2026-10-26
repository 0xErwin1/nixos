# The AI coding clients and the harness Gentle AI renders for them.
#
# Home Manager installs the client binaries; Gentle AI installs a harness into
# clients already present, never the clients themselves. The desired installation is declared here and `gentle-ai config render`
# produces the tree, so a change to how Gentle AI renders arrives with the
# package rather than needing a vendored copy re-synced.
#
# A client Gentle AI has no adapter for -- grok -- receives the harness
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

  # Locally authored skills live once, at ai/skills, and reach every client
  # through this one fill overlay per skills directory Gentle AI (or, for
  # Pi, this repo) actually reads -- fill only adds what is not already
  # there, so an upstream-rendered skill of the same name always wins and
  # our copy never shadows it.
  #
  # claude-code, opencode and codex each have their own skills directory in
  # gentle-ai-nix's internal/skills package (`internal/skills/skills.go`'s
  # `skillsDirs` table). Pi has none there -- its own package doc says so
  # explicitly ("Pi has no injectable skills concept at all") -- so this
  # entry is what puts our skills in `.pi/agent/skills`.
  #
  # grok and claude-work need no entry here: `customProviders` copies
  # their harness from `programs.gentle-ai.rendered`, the tree *after*
  # extraFiles is applied (see docs/options.md's `rendered` and
  # `customProviders.<name>.from` entries), so the skills this overlay
  # places under opencode's and claude-code's directories are already
  # present in what grok (from opencode) and claude-work (from
  # claude-code) copy. A second entry for them would only risk the same
  # skill landing twice for one client.
  localSkillsTargets = {
    claude-code = ".claude/skills";
    opencode = ".config/opencode/skills";
    codex = ".codex/skills";
    pi = ".pi/agent/skills";
  };

  localSkills = lib.mapAttrs' (
    name: target:
    lib.nameValuePair "${name}-skills" {
      inherit target;
      source = "${vendored}/skills";
      mode = "fill";
    }
  ) localSkillsTargets;

  ownPolicy = target: provider: {
    inherit target;
    source = "${vendored}/custom/policy/${provider}.md";
    mode = "append";
  };

  parPersonaBody = pkgs.runCommandLocal "par-persona-body" { } ''
    sed '1,/^---$/d' ${vendored}/custom/claude/output-styles/Par.md > "$out"
  '';

  # Pi gets Par from an extension instead of an AGENTS.md append: context files
  # land before gentle-pi's harness prompt, whose persona and reply-shape rules
  # then outrank Par. The extension appends Par after that harness.
  parPersonaPiPackage = pkgs.runCommandLocal "par-persona-pi" { } ''
    cp -r ${vendored}/custom/pi/par-persona "$out"
    chmod -R u+w "$out"
    cp ${parPersonaBody} "$out/par.md"
  '';

  parPersona = target: {
    inherit target;
    source = parPersonaBody;
    mode = "append";
  };

  secretsDirectory = "${config.home.homeDirectory}/.config/ai-harness/secrets";

  remote = url: headers: { inherit url headers; };
  local = command: args: { inherit command args; };

  # Every client gets these. The token placeholders resolve at activation from
  # the secret env files below, so nothing here reaches the Nix store as a
  # credential.
  sharedServers = {
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
    "open-pencil" = local (lib.getExe pkgs.open-pencil-mcp) [ ];
    obsidian = local "pnpx" [
      "@mauricio.wolff/mcp-obsidian@latest"
      "${config.home.homeDirectory}/Atlas"
    ];
    "dbflux-ui" = local "/home/iperez/dev/personal/Rust/dbflux-worktree/main/target/debug/gpui-mcp" [
      "--app-id"
      "dbflux"
    ];
  };

  # Pi authenticates to Atlas with its own token, every other client shares one.
  atlasFor =
    client:
    let
      token = if client == "pi" then "PI_ATLAS_TOKEN" else "CLAUDE_ATLAS_TOKEN";
    in
    remote "https://atlas.iperez.dev/mcp" {
      Authorization = "Bearer @${token}@";
    };

  # atlas and dbflux depend on which client connected, so they cannot be
  # shared: dbflux is told the client's name and atlas picks its token from it.
  serversFor =
    client:
    sharedServers
    // {
      atlas = atlasFor client;
      dbflux = local "dbflux-nightly" [
        "mcp"
        "--client-id"
        client
      ];
    }
    // lib.optionalAttrs (client == "claude") {
      clickup = local "npx" [
        "-y"
        "mcp-remote"
        "https://mcp.clickup.com/mcp"
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

  programs = {
    codex.enable = true;
    claude-code = {
      enable = true;
      package = pkgs.claude-code-latest;
    };
    opencode = {
      enable = true;
      package = pkgs.opencode;
    };
  };

  # gentle-ai and engram are installed by the gentle-ai module below: the
  # package that renders the configuration is the one that goes on PATH, so
  # what runs is what rendered, and engram comes from the same flake as the
  # component that configures it. Listing either here as well would put two
  # versions in one buildEnv.
  home.packages = with pkgs; [
    ccstatusline
    grok-build
    maestro
    pi-coding-agent-latest
    tuicr
  ];

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
        mcpServers = serversFor "claude";
        settings = {
          model = "opus[1m]";
          # Par is the reply voice everywhere. pi-claude-bridge loads these user
          # settings, so Pi sessions on the Claude bridge get it as their output
          # style too instead of the persona's Neutral.
          outputStyle = "Par";
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

        # The tip of gentle-shell's main branch, pinned by gentle-ai-nix,
        # instead of the npm release that flake supports.
        release = "main";

        # Launch through the standalone `gentle-shell`, which runs the Pi its
        # package carries under Node; gentle-pi is then provisioned from that
        # same package, so `pi` and `gentle-shell` load one copy. Under the
        # standalone Pi binary, gentle-pi's helper processes (its notification
        # audio among them) cannot start. `gentle-shell home link` makes it use
        # ~/.pi/agent, which is what this configuration renders.
        launcher.enable = true;
        mcpServers = serversFor "pi";
        packages = {
          "pi-claude-bridge" = "npm:pi-claude-bridge";
          "par-persona" = "${parPersonaPiPackage}";
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
        settings.theme = "Gentleman-Cute";
        # gentle-shell provides the compact codemode tool; loading Pi's built-in
        # implementation as well emits an extension collision at startup.
        settings.extensions = [ "-builtin:codemode" ];
        # gentle-pi agent profiles carry the whole routing: the orchestrator Pi
        # itself runs on and the model each phase agent gets. Naming one active
        # is the declarative form of applying it in /gentle:profiles, so a
        # switch is what a profile change takes. An agent a profile does not
        # name inherits whatever routing is in force outside the profile.
        activeProfile = "claude";
        profiles =
          let
            # The provider ids Pi resolves on this machine; `for` turns each one
            # into the constructor the profiles below name their models with, so
            # a binding reads as the model rather than as the pair it builds.
            models = inputs.gentle-ai-nix.lib.models;
            providers = models.for {
              codex = "openai-codex";
              nan = "nan";
              claude = "claude-bridge";
              moonshotai = "moonshotai";
            };
            sol = providers.onCodex "gpt-6.1-sol";
            luna = providers.onCodex "gpt-6-luna";
            terra = providers.onCodex "gpt-5.6-terra";
            astra = providers.onCodex "gpt-6-astra";
            glm53Flash = providers.onNan "glm5.3-flash";
            deepseekV4Flash = providers.onNan "deepseek-v4-flash";
            qwen38Flash = providers.onNan "qwen3.8-flash";
            opus = providers.onClaude "claude-opus-5-5";
            sonnet = providers.onClaude "claude-sonnet-5";
            kimi31pro = providers.onMoonshotai "kimi-k3.1-pro";
          in
          {
            kimi = {
              orchestrator = models.effort.max kimi31pro;
              phases = {
                jd-judge-a = models.effort.max kimi31pro;
                jd-judge-b = models.effort.max kimi31pro;
                jd-fix-agent = models.effort.max kimi31pro;
                gentle-ai-explore = models.effort.max kimi31pro;
                gentle-ai-verify = models.effort.max kimi31pro;
                gentle-ai-worker = models.effort.max kimi31pro;
                review-readability = models.effort.max kimi31pro;
                review-refuter = models.effort.max kimi31pro;
                review-reliability = models.effort.max kimi31pro;
                review-resilience = models.effort.max kimi31pro;
                review-risk = models.effort.max kimi31pro;
                review-validator = models.effort.max kimi31pro;
              };
            };

            codex = {
              orchestrator = models.effort.medium sol;
              phases = {
                jd-judge-a = models.effort.medium sol;
                jd-judge-b = models.effort.medium sol;
                jd-fix-agent = models.effort.low sol;
                gentle-ai-explore = models.effort.medium luna;
                gentle-ai-verify = models.effort.medium sol;
                gentle-ai-worker = models.effort.low sol;
                review-readability = models.effort.medium sol;
                review-refuter = models.effort.medium sol;
                review-reliability = models.effort.medium sol;
                review-resilience = models.effort.medium sol;
                review-risk = models.effort.medium sol;
                review-validator = models.effort.medium sol;
              };
            };

            nan = {
              orchestrator = models.effort.high deepseekV4Flash;
              phases = {
                jd-judge-a = models.effort.high glm53Flash;
                jd-judge-b = models.effort.high deepseekV4Flash;
                jd-fix-agent = models.effort.high glm53Flash;
                review-risk = models.effort.high glm53Flash;
                gentle-ai-worker = models.effort.high glm53Flash;
                gentle-ai-explore = models.effort.high deepseekV4Flash;
                gentle-ai-verify = models.effort.high deepseekV4Flash;
                review-refuter = models.effort.high deepseekV4Flash;
                review-readability = models.effort.high deepseekV4Flash;
                review-reliability = models.effort.high deepseekV4Flash;
                review-resilience = models.effort.high deepseekV4Flash;
                review-validator = models.effort.high deepseekV4Flash;
              };
            };

            mixedCodex = {
              orchestrator = models.effort.medium sol;
              phases = {
                jd-judge-a = models.effort.high sol;
                jd-judge-b = models.effort.high deepseekV4Flash;
                jd-fix-agent = models.effort.high glm53Flash;
                gentle-ai-explore = models.effort.high deepseekV4Flash;
                gentle-ai-worker = models.effort.high glm53Flash;
                gentle-ai-verify = models.effort.high sol;
                review-readability = models.effort.high sol;
                review-refuter = models.effort.high sol;
                review-reliability = models.effort.high sol;
                review-resilience = models.effort.high sol;
                review-risk = models.effort.high sol;
                review-validator = models.effort.high sol;
              };
            };

            mixedClaude = {
              orchestrator = models.effort.medium opus;
              phases = {
                jd-judge-a = models.effort.medium opus;
                jd-judge-b = models.effort.high deepseekV4Flash;
                jd-fix-agent = models.effort.high deepseekV4Flash;
                gentle-ai-explore = models.effort.high deepseekV4Flash;
                gentle-ai-worker = models.effort.high deepseekV4Flash;
                gentle-ai-verify = models.effort.medium opus;
                review-readability = models.effort.medium opus;
                review-refuter = models.effort.medium opus;
                review-reliability = models.effort.medium opus;
                review-resilience = models.effort.medium opus;
                review-risk = models.effort.medium opus;
                review-validator = models.effort.medium opus;
              };
            };

            claude = {
              orchestrator = models.effort.medium opus;
              phases = {
                gentle-ai-explore = models.effort.low opus;
                gentle-ai-worker = models.effort.low opus;
                gentle-ai-verify = models.effort.medium opus;
                jd-judge-a = models.effort.medium opus;
                jd-judge-b = models.effort.medium opus;
                jd-fix-agent = models.effort.low opus;
                review-readability = models.effort.medium opus;
                review-refuter = models.effort.medium opus;
                review-reliability = models.effort.medium opus;
                review-resilience = models.effort.medium opus;
                review-risk = models.effort.medium opus;
                review-validator = models.effort.medium opus;
              };
            };
          };
      };
    };

    components = {
      skills.enable = true;
      persona.enable = true;
      permissions.enable = true;
      sdd.enable = false;
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

    # Engram takes the channel `components.engram.release` starts at: `stable`,
    # the newest tagged release, whose Pi plugin comes from npm pinned to the
    # exact version that release ships. Naming it is only for taking `main`,
    # which is where the plugin line moves ahead of the last tag.

    backgroundSubagents = {
      opencode = "on";
      pi = "on";
    };

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
        # Pi owns its npm manifest at runtime; the native-MCP renderer has
        # no npm/package.json fragment to merge into that live file.

        # Merge declared servers into Pi's native MCP configuration so
        # activation preserves servers already present there. The retired
        # adapter's configuration is migrated before its package is removed.
        ".pi/agent/mcp.json"
      ];

      paths = [
        ".config/opencode/opencode.json"
      ]
      ++ map (name: ".claude/mcp/${name}.json") (builtins.attrNames (serversFor "claude"));

      envFiles = secretEnvFiles;
    };

    # Neither has a Gentle AI adapter, and both read the same kind of harness.
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
          # "engram-protocol.md" = "engram-protocol.md";
        };
      };
    };

    # Preserve the writable work-profile settings merge for client-owned state.
    overrideRendered = withWorkSettings;
    runtimeWritablePaths = [
      ".pi/gentle-ai/profiles.json"
      ".pi/gentle-ai/models.json"
    ];
    extraFiles = localSkills // {
      opencode-engram-plugin = {
        target = ".config/opencode/plugins/engram.ts";
        source = "${vendored}/custom/opencode/plugins/engram.ts";
      };

      grok-own = ownTree ".grok" "grok";
      opencode-own = ownTree ".config/opencode" "opencode";
      claude-own = ownTree ".claude" "claude";

      opencode-policy = ownPolicy ".config/opencode/AGENTS.md" "opencode";
      claude-policy = ownPolicy ".claude/CLAUDE.md" "claude";
      codex-policy = ownPolicy ".codex/AGENTS.md" "codex";

      # Grok owns AGENTS.md
      # outside its borrowed assets. Pi and Grok receive the compact local appendix
      # before Par, which must remain the exact suffix for each delivered policy.
      pi-local-policy = ownPolicy ".pi/agent/AGENTS.md" "pi-grok";
      grok-policy = ownPolicy ".grok/AGENTS.md" "pi-grok";
      opencode-shared-par-persona = parPersona ".config/opencode/AGENTS.md";
      codex-shared-par-persona = parPersona ".codex/AGENTS.md";
      grok-shared-par-persona = parPersona ".grok/AGENTS.md";
      claude-shared-par-persona = parPersona ".claude/CLAUDE.md";

      # Locally authored skills are wired above, through `localSkills`, into
      # every client that has a skills directory (or, for Pi, should have
      # one). See its comment for why grok and claude-work need nothing here.

      opencode-commands = own ".config/opencode/command" "command";
      opencode-tui = own ".config/opencode/tui.json" "opencode/tui.json";

      codex-engram-instructions = own ".codex/engram-instructions.md" "codex/engram-instructions.md";
      codex-engram-compact-prompt = own ".codex/engram-compact-prompt.md" "codex/engram-compact-prompt.md";

    };
  };

  # Provisioning keeps its skip because a fresh gentle-pi install otherwise
  # reaches an absolute host tar path that NixOS does not provide. Once that
  # package exists, rerun only its original lifecycle in a private FHS that
  # supplies /usr/bin/tar. Its installer retains the signed integrity decision
  # and is a no-op when the bundled Gentle AI is already valid.
  # gentle-pi's postinstall needs the FHS tar paths, wherever the package
  # landed: the npm prefix for the stable channel, the git checkout for main.
  # The checkout is named after the repository Pi clones -- gentle-shell, since
  # the rename -- while the package keeps its gentle-pi identity, so the two
  # spellings differ here on purpose. A path that stops existing is the quiet
  # failure this step exists to prevent: the repair reports nothing to do and
  # exits 0, and the bundled binary its postinstall would have extracted stays
  # missing, taking the native review preflight with it.
  #
  # The launcher's build carries that runtime in the store and Pi installs
  # gentle-pi from there, so neither path exists while it is enabled.
  home.activation.gentlePiRuntimeRepair =
    lib.mkIf (!config.programs.gentle-ai.providers.pi.launcher.enable)
      (
        lib.hm.dag.entryAfter [ "gentleAiProvisionPackages" ] ''
          run ${lib.getExe pkgs.gentle-pi-runtime-repair} --prefix ${lib.escapeShellArg "${config.home.homeDirectory}/.pi/agent/npm"}
          run ${lib.getExe pkgs.gentle-pi-runtime-repair} --package-dir ${lib.escapeShellArg "${config.home.homeDirectory}/.pi/agent/git/github.com/Gentleman-Programming/gentle-shell"}
        ''
      );

  # Native Pi migration copies legacy servers before retiring the adapter.
  # Retire only ClickUp from the two persisted Pi configs and Codex afterward;
  # otherwise a later migration would bring it back. Claude keeps its own
  # declared ClickUp MCP server, and unrelated client entries remain intact.
  home.activation.gentleAiRetireClickUpOutsideClaude =
    lib.hm.dag.entryAfter
      [
        "gentleAiMergedSecrets"
        "gentleAiMigratePiMCP"
        "gentleAiRetireDisplacedPiPackages"
      ]
      ''
        run ${lib.getExe pkgs.python3} ${vendored}/support/retire-clickup-mcp.py \
          --agent-dir ${lib.escapeShellArg "${config.home.homeDirectory}/.pi/agent"} \
          --codex-home ${lib.escapeShellArg "${config.home.homeDirectory}/.codex"} \
          --codex-bin ${lib.escapeShellArg "${config.home.profileDirectory}/bin/codex"}
      '';
}
