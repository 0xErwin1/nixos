{ pkgs, ... }:
{
  home = {
    packages = with pkgs; [
      lxappearance
      dconf
    ];
    sessionVariables = {
      GTK_THEME = "palenight";
      XCURSOR_THEME = "Bibata-Modern-Classic";
      XCURSOR_SIZE = "16";
    };
  };

  home.pointerCursor = {
    gtk.enable = true;
    x11.enable = true;
    package = pkgs.bibata-cursors;
    name = "Bibata-Modern-Classic";
    size = 16;
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
      name = "Bibata-Modern-Classic";
      package = pkgs.bibata-cursors;
    };
  };

  dconf.settings = {
    "org/gnome/desktop/interface" = {
      color-scheme = "prefer-dark";
      gtk-theme = "palenight";
      icon-theme = "Papirus-Dark";
      cursor-theme = "Bibata-Modern-Classic";
    };
  };
}
