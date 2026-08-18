{ inputs, pkgs, ... }:
{
  imports = [
    inputs.atlas.homeManagerModules.atlas-desktop
    ./zsh.nix
    ./git.nix
    ./gpg.nix
    ./tmux.nix
    ./herdr.nix
    ./direnv.nix
    ./zathura.nix
    ./ai.nix
    ./utilities.nix
    ./cpu-limit.nix
    ./scripts
  ];

  programs.atlas-desktop = {
    enable = true;
    package = inputs.atlas.packages.${pkgs.system}.atlas-desktop-nightly;
  };
}
