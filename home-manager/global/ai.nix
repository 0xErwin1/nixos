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
      settings = {
        extensions = [ ];
        packages = [ ];
        harness = {
          managedBy = "home-manager";
          source = "pi-harness";
        };
      };
      resources = [
        {
          source = inputs.pi-harness.assets.orchestrator;
          target = ".pi/agent/AGENTS.md";
        }
        {
          source = inputs.pi-harness.assets.agents;
          target = ".pi/agent/agents";
          recursive = true;
        }
        {
          source = inputs.pi-harness.assets.chains;
          target = ".pi/agent/chains";
          recursive = true;
        }
        {
          source = inputs.pi-harness.assets.support;
          target = ".pi/agent/support";
          recursive = true;
        }
        {
          source = inputs.pi-harness.assets.extensions;
          target = ".pi/agent/extensions";
          recursive = true;
        }
        {
          source = inputs.pi-harness.assets.packages;
          target = ".pi/agent/packages";
          recursive = true;
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
