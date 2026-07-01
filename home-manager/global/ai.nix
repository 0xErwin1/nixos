{ pkgs, ... }:
{
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

  home.packages = with pkgs; [
    ccstatusline
    engram
    codegraph
    claude-desktop
    pi-coding-agent
    tuicr
  ];
}
