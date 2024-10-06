let
  bind = import ./bind.nix;
in
{
  wayland.windowManager.hyprland = {
    enable = true;
    xwayland.enable = true;
    settings = {
      env = [
        "XCURSOR_SIZE, 24"
        "XDG_CURRENT_DESKTOP, Hyprland"
        "XDG_SESSION_TYPE, wayland"
        "XDG_SESSION_DESKTOP, Hyprland "
        "QT_QPA_PLATFORM, wayland;xcb"
        "QT_WAYLAND_DISABLE_WINDOWDECORATION, 1"
        "QT_AUTO_SCREEN_SCALE_FACTOR, 0"
        "QT_QPA_PLATFORMTHEME, qt6ct"
        "ELECTRON_OZONE_PLATFORM_HINT, auto"
        "MOZ_ENABLE_WAYLAND, 1"
      ];

      general = {
        gaps_in = 5;
        gaps_out = 20;
        border_size = 2;
        resize_on_border = true;
        layout = "dwindle";

        allow_tearing = false;
      };

      animation = {
        enabled = false;
      };

      "$mod" = "SUPER";
      "$terminal" = "kitty";
      "$browser" = "librewolf";
      "$workBrowser" = "firefox-developer-edition";

      inherit (bind) bind;
      inherit (bind) binde;
    };
  };
}
