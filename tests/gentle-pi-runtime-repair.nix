{ flake, pkgs }:

let
  repair = pkgs.callPackage ../pkgs/gentle-pi-runtime-repair { };
  profiles = [
    "iperez@delta"
    "iperez@epsilon"
    "iperez@zeta"
    "iperez@pi"
  ];
  activationFor = profile:
    flake.homeConfigurations.${profile}.config.home.activation.gentlePiRuntimeRepair;
  hasDagAndRunWrapper = profile:
    let
      entry = activationFor profile;
    in
    entry.after == [ "gentleAiProvisionPackages" ]
    && pkgs.lib.hasInfix "run " entry.data
    && pkgs.lib.hasInfix "gentle-pi-runtime-repair" entry.data;
  hasCorrectPrefix = profile:
    let
      prefix = pkgs.lib.escapeShellArg "${flake.homeConfigurations.${profile}.config.home.homeDirectory}/.pi/agent/npm";
    in
    pkgs.lib.hasInfix "--prefix ${prefix}" (activationFor profile).data;
in
assert builtins.all hasDagAndRunWrapper profiles;
assert builtins.all hasCorrectPrefix profiles
  || throw "gentle-pi runtime repair activation wrongprefix: expected \${homeDirectory}/.pi/agent/npm for delta, epsilon, zeta, and pi";
{
  runtimeTest = ''
    ${pkgs.bash}/bin/bash ${./gentle-pi-runtime-repair.sh} ${repair}/bin/gentle-pi-runtime-repair
  '';
}
