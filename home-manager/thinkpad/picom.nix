{ pkgs, ... }:
{

  services.picom = {
    enable = true;
    vSync = true;
    shadow = true;
    fade = true;
    shadowExclude = [
      "window_type = 'dock'"
      "window_type = 'desktop'"
      "class_g = 'slop'"
      "window_type = 'menu'"
      "window_type = 'desktop'"
      "class_g = 'Firefox' && window_type *= 'utility'"
      "class_g = 'google-chrome' && window_type *= 'utility'"
      "_GTK_FRAME_EXTENTS@:c"
      "name = 'cpt_frame_xcb_window'"
      "class_g ?= 'zoom'"
    ];

    settings = {
      corner-radius = 5;
      rounded-corners-exclude = [
        "window_type = \"dock\""
        "window_type = \"desktop\""
        "class_g = 'Polybar'"
        "name = 'xmobar'"
        "name = 'eww'"
        "name = 'trayer'"
        #"!window_type = 'normal'",
        "class_g ?= 'rofi'"
      ];
    };
  };
}
