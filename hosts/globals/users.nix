{ pkgs, ... }:
{
  programs.zsh.enable = true;

  users.users.iperez = {
    isNormalUser = true;
    home = "/home/iperez";
    extraGroups = [
      "networkmanager"
      "wheel"
      "audio"
    ];
    shell = pkgs.zsh;
  };
}
