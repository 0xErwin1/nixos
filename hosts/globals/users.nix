{ pkgs, ... }:
{
  users.users.iperez = {
    isNormalUser = true;
    description = "";
    extraGroups = [
      "networkmanager"
      "wheel"
      "docker"
      "audio"
    ];
    shell = pkgs.zsh;
  };

  programs.zsh.enable = true;
}
