{ pkgs, inputs, ... }:
let
  spicePkgs = inputs.spicetify-nix.legacyPackages.${pkgs.system};
in
{
  imports = [
    inputs.spicetify-nix.homeManagerModules.default
  ];

  home.packages = with pkgs; [
    spotify
  ];

  programs.spicetify = {
    enable = false;
    enabledExtensions = with spicePkgs.extensions; [
      hidePodcasts
      shuffle
      keyboardShortcut
    ];
    theme = spicePkgs.themes.text;
    colorScheme = "text";
  };
}
