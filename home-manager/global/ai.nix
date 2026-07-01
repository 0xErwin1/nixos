{ pkgs, inputs, ... }:
{
  imports = [
    inputs.pi-harness.homeModules.default
    ./ai-harness.nix
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
    pi.coding-agent = {
      enable = true;
      package = inputs.pi-harness.packages.${pkgs.stdenv.hostPlatform.system}.default;
      settings.harness = {
        managedBy = "home-manager";
        source = "pi-harness";
      };
      resources = [
        {
          source = inputs.pi-harness.assets.orchestrator;
          target = ".local/share/pi-harness/assets/orchestrator.md";
        }
      ];
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
