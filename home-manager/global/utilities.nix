{ pkgs, ... }:
{
  home.packages = with pkgs; [
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
    fd
    ripgrep
    pcmanfm
  ];

  # programs = {
  #   taskwarrior = {
  #     package = pkgs.taskwarrior3;
  #     enable = true;
  #     config = {
  #       weekly = {
  #         due = true;
  #         reminder = true;
  #         report = true;
  #       };
  #       monthly = {
  #         due = true;
  #         reminder = true;
  #         report = true;
  #       };
  #       data = {
  #         location = "~/.task";
  #       };
  #     };
  #   };
  # };
}
