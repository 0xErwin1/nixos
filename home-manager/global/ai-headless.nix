{ pkgs, ... }:
{
  imports = [
    ./ai-harness-gentle-ai.nix
  ];

  programs = {
    codex.enable = true;
    claude-code = {
      enable = true;
      package = pkgs.claude-code-latest;
    };
    opencode = {
      enable = true;
      package = pkgs.opencode;
    };
  };

  # Pi's harness comes from Gentle AI now, declared in ai-harness-gentle-ai.nix
  # like every other client's. The Pi binary stays a plain package below: Gentle
  # AI installs a harness into an already-present Pi, never Pi itself.
  #
  # gentle-ai is installed by ai-harness-gentle-ai.nix: the package that renders
  # the configuration is the one that goes on PATH, so what runs is what
  # rendered. Listing it here as well put two versions in one buildEnv.
  home.packages = with pkgs; [
    ccstatusline
    codegraph
    engram
    grok-build
    maestro
    pi-coding-agent
    tuicr
  ];
}
