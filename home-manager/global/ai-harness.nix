{ config, lib, pkgs, ... }:

let
  resourceMatrix = import ./ai-harness-resources.nix;
  canonicalRoot = builtins.path {
    path = ../../ai;
    name = "ai-harness";
  };
  homeDirectory = config.home.homeDirectory;

  resourcesFor = delivery: lib.filter (resource: resource.delivery or null == delivery) resourceMatrix.families;
  toRuntimeResource = resource:
    (builtins.removeAttrs resource [ "name" "classification" "delivery" "kind" "paths" ])
    // { source = canonicalRoot + "/${resource.source}"; };

  projectedResources = map toRuntimeResource (resourcesFor "project");

  # Assets that must arrive as real files rather than Nix-store symlinks.
  #
  # Agens refuses to load any agent, command, or skill reached through a
  # symbolic link: its markdown loader rejects a symlinked definition and then
  # rejects the canonicalized path for escaping its root, and its skill loader
  # opens every directory and manifest with O_NOFOLLOW. A `home.file` projection
  # is symlinks all the way down, so it would leave agens with an empty catalog.
  # These entries are therefore copied at activation and the copy is authoritative:
  # each target is replaced wholesale on every switch, so local edits under it do
  # not survive. Only agens needs this; every other agent takes the symlink path
  # above.
  copiedResources = map toRuntimeResource (resourcesFor "copy");

  # Config files that must carry secret values into their final on-disk
  # location. They cannot be Nix-store symlinks (read-only, so tokens could not
  # be edited) and must not hold secrets in Git, so Home Manager renders them at
  # activation from the canonical template, substituting @VAR@ placeholders with
  # values sourced from the secret env files. Extend this list as more agents'
  # MCP configs get centralized.
  toTemplateResource = resource:
    (builtins.removeAttrs resource [ "name" "classification" "delivery" "source" "paths" ])
    // { template = canonicalRoot + "/${resource.source}"; };

  renderedSecretConfigs = map toTemplateResource (resourcesFor "render");

  # Agents whose config file holds state Home Manager must not own: state the
  # agent writes itself at runtime (Claude Code's OAuth/project history in
  # .claude.json; Codex's project trust levels, notices, and plugin state in
  # config.toml), or -- for agens -- settings the user edits by hand, such as
  # the default provider and model. A whole-file render would clobber them.
  # For Agens, the merge helper replaces only a comment-delimited managed block.
  # Its first run removes canonical MCP tables, their descendants, and the
  # permission table so the target remains valid TOML, while unrelated user and
  # runtime settings survive.
  mergedSecretConfigs = map toTemplateResource (resourcesFor "merge");

  renderTemplateSources =
    (map (entry: entry.template) renderedSecretConfigs)
    ++ (map (entry: entry.template) mergedSecretConfigs);

  copyTargets = map (entry: entry.target) copiedResources;
  copySources = map (entry: entry.source) copiedResources;

  copyCommands = lib.concatMapStringsSep "\n" (
    entry: ''
      copy_resource ${lib.escapeShellArg (toString entry.source)} ${lib.escapeShellArg "${homeDirectory}/${entry.target}"}
    ''
  ) copiedResources;

  renderCommands = lib.concatMapStringsSep "\n" (
    entry: ''
      render_secret_config ${lib.escapeShellArg (toString entry.template)} ${lib.escapeShellArg "${homeDirectory}/${entry.target}"}
    ''
  ) renderedSecretConfigs;

  mergeCommands = lib.concatMapStringsSep "\n" (
    entry: ''
      merge_secret_config ${lib.escapeShellArg entry.kind} ${lib.escapeShellArg (toString entry.template)} ${lib.escapeShellArg "${homeDirectory}/${entry.target}"}
    ''
  ) mergedSecretConfigs;

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
  managedResources = lib.filter (resource: resource.delivery or null != null) resourceMatrix.families;
  managedTargets = map (resource: resource.target) managedResources;
  managedSources = map (resource: resource.source) managedResources;

  # Recursive resources are materialized by Home Manager as a real directory
  # whose leaf files are the managed symlinks, so the directory itself is never
  # a symlink. Only single-file targets are whole-path symlinks, so the
  # unmanaged-collision guard applies solely to them; checking a recursive
  # directory's top level would abort on every switch after the first.
  projectionPreflightChecks = lib.concatMapStringsSep "\n" (
    resource:
    lib.optionalString (!(resource.recursive or false)) ''
      target_path=${lib.escapeShellArg "${homeDirectory}/${resource.target}"}

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
    ''
  ) projectedResources;

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
      assertion = lib.length managedTargets == lib.length (lib.unique managedTargets);
      message = "AI harness ownership matrix must map every managed target exactly once.";
    }
    {
      assertion = lib.length managedSources == lib.length (lib.unique managedSources);
      message = "AI harness ownership matrix must map every managed source exactly once.";
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
      assertion = lib.length copyTargets == lib.length (lib.unique copyTargets);
      message = "AI harness copied-resource targets must be unique.";
    }
    {
      assertion = lib.all builtins.pathExists copySources;
      message = "AI harness copied-resource sources must exist under the canonical Home Manager ai/ tree.";
    }
    {
      assertion = lib.all (target: !(lib.elem target projectionTargets)) copyTargets;
      message = "AI harness targets must be either projected or copied, never both.";
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

    ${projectionPreflightChecks}
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

  home.activation.aiHarnessCopiedResources = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    set -eu

    # The target is replaced wholesale rather than merged: a stale agent or skill
    # left behind from a previous generation would keep loading, and there is no
    # per-file ownership record to prune it from. The copy is also chmod'd
    # writable because the Nix store source is read-only, and agens refuses a
    # skill manifest with more than one hard link, which rules out `cp -l`.
    copy_resource() {
      source="$1"
      target="$2"

      mkdir -p "$(dirname "$target")"
      rm -rf "$target"
      cp -rL --no-preserve=mode,ownership "$source" "$target"
      chmod -R u+rwX "$target"
    }

    ${copyCommands}
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

    merge_secret_config() {
      kind="$1"
      template="$2"
      target="$3"

      mkdir -p "$(dirname "$target")"

      ${pkgs.python3}/bin/python3 ${./ai-harness-merge.py} "$kind" "$template" "$target"
    }

    ${renderCommands}

    ${mergeCommands}
  '';
}
