{ config, pkgs, ... }:

{
  services.sunshine = {
    enable = true;
    autoStart = true;

    capSysAdmin = true;

    openFirewall = true;
  };

  environment.systemPackages = with pkgs; [
    sunshine
    moonlight-qt
    pavucontrol
    wl-clipboard
    xdg-utils
  ];
}
