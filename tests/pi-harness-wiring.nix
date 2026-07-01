{ flake }:

let
  hosts = [
    "iperez@delta"
    "iperez@epsilon"
    "iperez@zeta"
  ];
  expectedResourceSources = {
    ".pi/agent/AGENTS.md" = toString flake.inputs.pi-harness.assets.orchestrator;
    ".pi/agent/agents" = toString flake.inputs.pi-harness.assets.agents;
    ".pi/agent/chains" = toString flake.inputs.pi-harness.assets.chains;
    ".pi/agent/support" = toString flake.inputs.pi-harness.assets.support;
    ".pi/agent/extensions" = toString flake.inputs.pi-harness.assets.extensions;
    ".pi/agent/packages" = toString flake.inputs.pi-harness.assets.packages;
  };
  expectedResourceTargets = builtins.attrNames expectedResourceSources;
  forbiddenPiTargets = [
    ".pi/agent/settings.json"
    ".pi/agent/mcp.json"
    ".pi/agent/auth.json"
  ];
  isHomeManagerAiSource = source: builtins.match ".*/ai/.*" source != null;
  hostState =
    host:
    let
      homeConfiguration = flake.homeConfigurations.${host};
      cfg = homeConfiguration.config.programs.pi.coding-agent;
      system = homeConfiguration.pkgs.stdenv.hostPlatform.system;
      expectedPackage = flake.inputs.pi-harness.packages.${system}.default;
      resourcesByTarget = builtins.listToAttrs (
        map (resource: {
          name = resource.target;
          value = toString resource.source;
        }) cfg.resources
      );
      resourceTargets = map (resource: resource.target) cfg.resources;
      piResourceSources = map (target: resourcesByTarget.${target}) expectedResourceTargets;
    in
    {
      moduleEnabled = cfg.enable;
      packageName = cfg.package.pname or cfg.package.name;
      expectedPackageName = expectedPackage.pname or expectedPackage.name;
      inherit resourceTargets piResourceSources;
      settings = cfg.settings;
      hasExpectedPiTargets = builtins.all (
        target: builtins.elem target resourceTargets
      ) expectedResourceTargets;
      piTargetsAvoidRuntimeState = builtins.all (
        target: !(builtins.elem target forbiddenPiTargets)
      ) resourceTargets;
      piResourcesMatchHarnessAssets = builtins.all (
        target: resourcesByTarget.${target} == expectedResourceSources.${target}
      ) expectedResourceTargets;
      piResourcesDoNotComeFromHomeManagerAi = builtins.all (
        source: !(isHomeManagerAiSource source)
      ) piResourceSources;
    };
  states = map (host: {
    inherit host;
    state = hostState host;
  }) hosts;
  validState =
    item:
    item.state.moduleEnabled
    && item.state.packageName == item.state.expectedPackageName
    && item.state.hasExpectedPiTargets
    && item.state.piTargetsAvoidRuntimeState
    && item.state.piResourcesMatchHarnessAssets
    && item.state.piResourcesDoNotComeFromHomeManagerAi
    && item.state.settings.harness.managedBy == "home-manager"
    && item.state.settings.harness.source == "pi-harness";
in
assert flake.inputs ? pi-harness;
assert builtins.all validState states;
{
  hasInput = true;
  checkedHosts = map (item: item.host) states;
  inherit expectedResourceSources states;
}
