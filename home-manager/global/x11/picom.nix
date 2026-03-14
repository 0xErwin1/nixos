{
  services.picom = {
    enable = true;
    vSync = true;
    shadow = true;
    fade = true;
    backend = "glx";
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
        "!window_type = 'normal'"
        "class_g ?= 'rofi'"
      ];
      fading = true;
      fade-in-step = 1.0e-2;
      fade-out-step = 1.0e-2;
      fade-delta = 1;
      no-fading-openclose = false;
      no-fading-destroyed-argb = true;
      fade-exclude = [ "class_g = 'slop'" ];

      opacity = 1;
      inactive-opacity = 1;
      frame-opacity = 1;
      inactive-opacity-override = false;
      active-opacity = 1.0;
      inactive-dim = 0.0;
    };
  };
}
