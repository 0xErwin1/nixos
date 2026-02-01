{ pkgs, ... }:
{
  home = {
    packages = with pkgs; [
      lxappearance
      dconf
    ];
    sessionVariables = {
      GTK_THEME = "palenight";
    };
  };

  gtk = {
    enable = true;

    gtk3.extraConfig = {
      gtk-application-prefer-dark-theme = true;
    };

    gtk4.extraConfig = {
      gtk-application-prefer-dark-theme = true;
    };

    font = {
      name = "LiterationSans Nerd Font Regular";
      size = 12;
    };

    theme = {
      name = "palenight";
      package = pkgs.palenight-theme;
    };

    iconTheme = {
      name = "Papirus-Dark";
      package = pkgs.papirus-icon-theme;
    };

    cursorTheme = {
      name = "vimix-cursors";
      package = pkgs.vimix-cursors;
    };
  };

  dconf.settings = {
    "org/gnome/desktop/interface" = {
      color-scheme = "prefer-dark";
      gtk-theme = "palenight";
      icon-theme = "Papirus-Dark";
      cursor-theme = "vimix-cursors";
    };
  };
}
