{ pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    mangohud
    solaar
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
    gamescope = {
      enable = true;
    };
  };
}
