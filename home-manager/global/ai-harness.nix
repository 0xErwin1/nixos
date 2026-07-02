{ config, lib, pkgs, ... }:

let
  canonicalRoot = ../../ai;
  homeDirectory = config.home.homeDirectory;

  projectedResources = [
    {
      source = canonicalRoot + "/skills";
      target = ".agents/skills";
      recursive = true;
    }
    {
      source = canonicalRoot + "/opencode/AGENTS.md";
      target = ".config/opencode/AGENTS.md";
    }
    {
      source = canonicalRoot + "/opencode/ORCHESTRATOR.md";
      target = ".config/opencode/ORCHESTRATOR.md";
    }
    {
      source = canonicalRoot + "/opencode/agent";
      target = ".config/opencode/agent";
      recursive = true;
    }
    {
      source = canonicalRoot + "/opencode/commands";
      target = ".config/opencode/commands";
      recursive = true;
    }
    {
      source = canonicalRoot + "/command";
      target = ".config/opencode/command";
      recursive = true;
    }
    {
      source = canonicalRoot + "/opencode/skills";
      target = ".config/opencode/skills";
      recursive = true;
    }
    {
      source = canonicalRoot + "/opencode/tui.json";
      target = ".config/opencode/tui.json";
    }
    {
      source = canonicalRoot + "/claude/CLAUDE.md";
      target = ".claude/CLAUDE.md";
    }
    {
      source = canonicalRoot + "/claude/sdd-orchestrator.md";
      target = ".claude/sdd-orchestrator.md";
    }
    {
      source = canonicalRoot + "/claude/engram-protocol.md";
      target = ".claude/engram-protocol.md";
    }
    {
      source = canonicalRoot + "/claude/agents";
      target = ".claude/agents";
      recursive = true;
    }
    {
      source = canonicalRoot + "/claude/commands";
      target = ".claude/commands";
      recursive = true;
    }
    {
      source = canonicalRoot + "/claude/skills";
      target = ".claude/skills";
      recursive = true;
    }
    {
      source = canonicalRoot + "/codex/AGENTS.md";
      target = ".codex/AGENTS.md";
    }
    {
      source = canonicalRoot + "/codex/sdd-orchestrator.md";
      target = ".codex/sdd-orchestrator.md";
    }
    {
      source = canonicalRoot + "/codex/engram-instructions.md";
      target = ".codex/engram-instructions.md";
    }
    {
      source = canonicalRoot + "/codex/skills";
      target = ".codex/skills";
      recursive = true;
    }
  ];

  # Config files that must carry secret values into their final on-disk
  # location. They cannot be Nix-store symlinks (read-only, so tokens could not
  # be edited) and must not hold secrets in Git, so Home Manager renders them at
  # activation from the canonical template, substituting @VAR@ placeholders with
  # values sourced from the secret env files. Extend this list as more agents'
  # MCP configs get centralized.
  renderedSecretConfigs = [
    {
      template = canonicalRoot + "/opencode/opencode.jsonc";
      target = ".config/opencode/opencode.jsonc";
    }
    # Prepared for future centralization; add a template under ai/ and uncomment:
    # { template = canonicalRoot + "/claude/claude.json";  target = ".claude.json"; }
    # { template = canonicalRoot + "/codex/config.toml";   target = ".codex/config.toml"; }
    # { template = canonicalRoot + "/pi/mcp.json";         target = ".pi/agent/mcp.json"; }
  ];

  renderTemplateSources = map (entry: entry.template) renderedSecretConfigs;

  renderCommands = lib.concatMapStringsSep "\n" (
    entry: ''
      render_secret_config ${lib.escapeShellArg (toString entry.template)} ${lib.escapeShellArg "${homeDirectory}/${entry.target}"}
    ''
  ) renderedSecretConfigs;

  sourceSecretEnvFiles = lib.concatMapStringsSep "\n" (
    entry: ''
      set -a
      . ${lib.escapeShellArg entry.path}
      set +a
    ''
  ) secretEnvContract;

  secretEnvContract = [
    {
      envVar = "AI_HARNESS_MCP_ENV_FILE";
      path = "${homeDirectory}/.config/ai-harness/secrets/mcp.env";
    }
    {
      envVar = "AI_HARNESS_API_ENV_FILE";
      path = "${homeDirectory}/.config/ai-harness/secrets/api.env";
    }
  ];

  secretEnvironment = lib.listToAttrs (
    map (entry: {
      name = entry.envVar;
      value = entry.path;
    }) secretEnvContract
  );

  projectionTargets = map (resource: resource.target) projectedResources;
  projectionSources = map (resource: resource.source) projectedResources;
  shellTargets = lib.concatMapStringsSep " " (target: lib.escapeShellArg target) projectionTargets;
  shellSecretEnvFiles = lib.concatMapStringsSep " " (
    entry: lib.escapeShellArg entry.path
  ) secretEnvContract;
in
{
  assertions = [
    {
      assertion = lib.length projectionTargets == lib.length (lib.unique projectionTargets);
      message = "AI harness projection targets must be unique.";
    }
    {
      assertion = lib.all builtins.pathExists projectionSources;
      message = "AI harness projection sources must exist under the canonical Home Manager ai/ tree.";
    }
    {
      assertion = lib.all builtins.pathExists renderTemplateSources;
      message = "AI harness rendered-config templates must exist under the canonical Home Manager ai/ tree.";
    }
    {
      assertion = lib.all (
        entry: builtins.match ".*(=|Bearer|sk-|gh[pousr]_|xox[baprs]-).*" entry.path == null
      ) secretEnvContract;
      message = "AI harness secret contract may reference only env file paths, not token-like values.";
    }
  ];

  programs.pi.coding-agent = {
    resources = lib.mkAfter projectedResources;
    environment = secretEnvironment;
  };

  home.activation.aiHarnessProjectionPreflight = lib.hm.dag.entryBefore [ "writeBoundary" ] ''
    set -eu

    for target in ${shellTargets}; do
      target_path="$HOME/$target"

      if [ -L "$target_path" ]; then
        link_target="$(readlink "$target_path")"
        case "$link_target" in
          /nix/store/*) ;;
          *)
            echo "AI harness projection target already exists as an unmanaged symlink: $target_path -> $link_target" >&2
            echo "Move or back up the unmanaged symlink before running home-manager switch." >&2
            exit 1
            ;;
        esac
      elif [ -e "$target_path" ]; then
        echo "AI harness projection target already exists and is not a Home Manager symlink: $target_path" >&2
        echo "Move or back up the unmanaged file before running home-manager switch." >&2
        exit 1
      fi
    done
  '';

  home.activation.aiHarnessSecretsPreflight = lib.hm.dag.entryBefore [ "writeBoundary" ] ''
    set -eu

    for secret_env_file in ${shellSecretEnvFiles}; do
      if [ ! -f "$secret_env_file" ]; then
        echo "AI harness required env file is missing: $secret_env_file" >&2
        echo "Create the file locally with mode 600 before running home-manager switch; do not commit token values." >&2
        exit 1
      fi
    done
  '';

  home.activation.aiHarnessSecretConfigRender = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    set -eu

    ${sourceSecretEnvFiles}

    render_secret_config() {
      template="$1"
      target="$2"

      if [ -L "$target" ]; then
        rm "$target"
      fi

      mkdir -p "$(dirname "$target")"

      ${pkgs.python3}/bin/python3 ${./ai-harness-render.py} "$template" "$target"
    }

    ${renderCommands}
  '';
}
