{ flake }:

let
  desktopProfiles = [
    "iperez@delta"
    "iperez@epsilon"
    "iperez@zeta"
  ];
  atlasPackage = flake.inputs.atlas.packages.x86_64-linux.atlas-desktop-nightly;
  atlasConfig = profile: flake.homeConfigurations.${profile}.config.programs.atlas-desktop;
  piPrograms = flake.homeConfigurations."iperez@pi".config.programs;
in
assert builtins.all (profile: (atlasConfig profile).enable) desktopProfiles;
assert builtins.all (
  profile: (atlasConfig profile).package.outPath == atlasPackage.outPath
) desktopProfiles;
assert !(builtins.hasAttr "atlas-desktop" piPrograms);
{
  inherit desktopProfiles;
  package = atlasPackage.outPath;
}
