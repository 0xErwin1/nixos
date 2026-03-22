{
  xdg.configFile."hypr/hyprpaper.conf" = {
    source = ./hyprpaper.conf;
    recursive = true;
  };

  services.hyprpaper = {
    enable = true;
  };
}
