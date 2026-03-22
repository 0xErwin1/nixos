{ pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    mangohud
  ];

  programs = {
    steam = {
      enable = true;
      remotePlay.openFirewall = true;
      dedicatedServer.openFirewall = true;
      localNetworkGameTransfers.openFirewall = true;
    };
    gamemode = {
      enable = true;
    };
  };
}
