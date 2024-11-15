{ pkgs, ... }:
{
  home = {
    packages = with pkgs; [ lxappearance ];
    sessionVariables.GTK_THEME = "palenight";
  };

  gtk = {
    enable = true;

    gtk3.extraConfig = {
      Settings = ''
        gtk-application-prefer-dark-theme=1
      '';
    };

    gtk4.extraConfig = {
      Settings = ''
        gtk-application-prefer-dark-theme=1
      '';
    };

    font = {
      name = "LiterationSans Nerd Font";
      size = 12;
    };

    theme = {
      name = "palenight";
      package = pkgs.palenight-theme;
    };

    iconTheme = {
      name = "Papirus";
      package = pkgs.papirus-icon-theme;
    };

    cursorTheme = {
      name = "Numix-Cursor";
      package = pkgs.numix-cursor-theme;
    };
  };
}
