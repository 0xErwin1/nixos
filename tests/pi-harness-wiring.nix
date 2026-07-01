{ flakePath }:

let
  flake = builtins.getFlake ("path:" + flakePath);
  hosts = [
    "iperez@delta"
    "iperez@epsilon"
    "iperez@zeta"
  ];
  expectedResourceTarget = ".local/share/pi-harness/assets/orchestrator.md";
  hostState =
    host:
    let
      homeConfiguration = flake.homeConfigurations.${host};
      cfg = homeConfiguration.config.programs.pi.coding-agent;
      system = homeConfiguration.pkgs.stdenv.hostPlatform.system;
      expectedPackage = flake.inputs.pi-harness.packages.${system}.default;
    in
    {
      moduleEnabled = cfg.enable;
      packageName = cfg.package.pname or cfg.package.name;
      expectedPackageName = expectedPackage.pname or expectedPackage.name;
      resourceTargets = map (resource: resource.target) cfg.resources;
      settings = cfg.settings;
    };
  states = map (host: {
    inherit host;
    state = hostState host;
  }) hosts;
  validState =
    item:
    item.state.moduleEnabled
    && item.state.packageName == item.state.expectedPackageName
    && builtins.elem expectedResourceTarget item.state.resourceTargets
    && item.state.settings.harness.managedBy == "home-manager"
    && item.state.settings.harness.source == "pi-harness";
in
assert flake.inputs ? pi-harness;
assert builtins.all validState states;
{
  hasInput = true;
  checkedHosts = map (item: item.host) states;
  inherit states;
}
