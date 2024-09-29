{ pkgs, ... }:
{
  home.packages = with pkgs; [
    nchat
    ncdu
    tokei
    fastfetch
    onefetch
    eza
    bat
    zsh
    curl
    wget
    btop
    delta
    kalker
    udiskie
    fd
    ripgrep
  ];

  programs = {
    taskwarrior = {
      package = pkgs.taskwarrior3;
      enable = true;
      config = {
        weekly = {
          due = true;
          reminder = true;
          report = true;
        };
        monthly = {
          due = true;
          reminder = true;
          report = true;
        };
      };
    };
  };
}
