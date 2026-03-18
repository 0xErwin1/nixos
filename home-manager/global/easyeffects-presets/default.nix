{ lib, ... }:
let
  loadPreset = file: {
    name = lib.removeSuffix ".json" (baseNameOf file);
    value = builtins.fromJSON (builtins.readFile file);
  };

  presetFiles = builtins.filter (f: lib.hasSuffix ".json" f) (
    map (f: ./. + "/${f}") (builtins.attrNames (builtins.readDir ./.))
  );

  presets = builtins.listToAttrs (map loadPreset presetFiles);
in
{
  services.easyeffects.extraPresets = presets;
}
