{
  config,
  inputs,
  ...
}:
{
  imports = [
    inputs.sops-nix.homeManagerModules.sops
    ../global/browser.nix
    ../global/terminal.nix
    ../global
    ../global/git.nix
    ../global/xdg.nix
    ../global/phone-automount.nix
    ../global/zed
    ../global/font.nix
    ../global/window-managers/hyprland
    #../global/window-managers/leftwm
    ../global/audio.nix
    ../global/themes.nix
    ../global/communication.nix
    ../global/database.nix
    ../global/neovim.nix
    ../global/zathura.nix
    ../global/music.nix
    ../global/voxtype.nix
    ../global/bar/default.nix
    #../global/x11
    #./x11.nix
    #./monitor.nix
    ./kanshi.nix
    ./kokoro-tts.nix
    ./packages.nix
  ];

  home = {
    enableNixpkgsReleaseCheck = false;
    username = "iperez";
    homeDirectory = "/home/iperez";
    stateVersion = "25.11";
    sessionVariables = {
      EDITOR = "nvim";
    };
  };

  sops = {
    defaultSopsFile = ../../secrets/ai.yaml;
    age.keyFile = "${config.home.homeDirectory}/.config/sops/age/keys.txt";

    secrets = {
      "mcp-env" = {
        path = "${config.home.homeDirectory}/.config/ai-harness/secrets/mcp.env";
        mode = "0600";
      };
      "api-env" = {
        path = "${config.home.homeDirectory}/.config/ai-harness/secrets/api.env";
        mode = "0600";
      };
      "engram-cloud-token" = {
        mode = "0400";
      };
    };
  };

  programs = {
    home-manager.enable = true;

    gentle-ai.components.engram.cloud = {
      server = "https://engram.iperez.dev";
      tokenFile = config.sops.secrets."engram-cloud-token".path;
    };
  };

  services = {
    syncthing = {
      enable = true;
      extraOptions = [
        "--config=/home/iperez/.config/syncthing"
        "--data=/home/iperez"
      ];
    };
  };

  systemd.user.services.syncthing.Service.Slice = "background.slice";

  # Intel iGPU enumerates as Vulkan device 0, the discrete NVIDIA as 1; whisper
  # would otherwise transcribe on the slow iGPU.
  local.voxtype.gpuDevice = 1;
}
