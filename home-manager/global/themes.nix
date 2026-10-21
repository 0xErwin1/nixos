# GTK, icon and cursor theming. The light/dark part is owned by wl-theme
# (./theme): its `dconf.ini` sets `color-scheme`, `gtk-theme` and `icon-theme`
# at runtime, so nothing here may pin them. The static theme below only fills
# settings.ini for apps that cannot read dconf and matches the default theme.
{
  pkgs,
  lib,
  config,
  ...
}:
{
  home = {
    packages = with pkgs; [
      lxappearance
      dconf
    ];
    sessionVariables = {
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

    # libadwaita follows `color-scheme`; a theme here would be imported into
    # gtk-4.0/gtk.css and pin one mode. Explicit because the pre-26.05 default
    # inherits gtk.theme.
    gtk4.theme = null;

    font = {
      name = "LiterationSans Nerd Font Regular";
      size = 12;
    };

    theme = {
      name = "adw-gtk3-dark";
      package = pkgs.adw-gtk3;
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

  # Forced because the GTK module also derives `gtk-theme` and `icon-theme` here
  # from gtk.theme and gtk.iconTheme, and activation would reset the running
  # theme's values. This replaces the whole set, so it lists every key that
  # stays declarative: the cursor and the font the GTK module would write.
  dconf.settings."org/gnome/desktop/interface" = lib.mkForce {
    cursor-theme = config.gtk.cursorTheme.name;
    font-name = "${config.gtk.font.name} ${toString config.gtk.font.size}";

    # GTK4 ignores hinting and positions glyphs at subpixel offsets; GTK3 apps
    # (wofi among them) hint by default, so the same font renders thinner and
    # snapped to the pixel grid. Unhinted grayscale makes them match.
    font-hinting = "none";
    font-antialiasing = "grayscale";
  };
}
