{ pkgs, ... }:
{
  home.packages = with pkgs; [
    lxappearance
  ];

  gtk = {
    enable = true;

    theme = {
      name = "Nordic-darker";
      package = pkgs.nordic;
    };

    iconTheme = {
      name = "Papirus";
      package = pkgs.papirus-icon-theme;
    };

    cursorTheme = {
      name = "Nordic-cursors";
    };
  };
}
