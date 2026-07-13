{pkgs ? import <nixpkgs> {}}:
{
  default = pkgs.mkShell {
    DEVENV_TUI = "false";
    NIX_CONFIG = "extra-experimental-features = nix-command flakes";
    nativeBuildInputs = with pkgs; [
      deploy-rs
      devenv
      secretspec
      wireguard-tools
      openssh
      nix
      home-manager
      git
    ];
  };
}
