{
  services.dunst = {
    enable = true;
    settings = {
      global = {
        monitor = 0;
        follow = "mouse";

        width = 350;
        height = 500;
        origin = "top-right";
        offset = "10x25";
        scale = 0;
        notification_limit = 0;
        progress_bar = true;

        progress_bar_height = 10;

        progress_bar_frame_width = 1;
        progress_bar_min_width = 150;

        progress_bar_max_width = 300;

        indicate_hidden = true;

        # The transparency of the window.  Range: [0; 100].
        # This option will only work if a compositing window manager is
        # present (e.g. xcompmgr, compiz, etc.). (X11 only)
        transparency = 0;

        separator_height = 2;

        padding = 10;

        horizontal_padding = 10;

        text_icon_padding = 0;

        frame_width = 2;

        frame_color = "#73B8FF";

        gap_size = 0;

        separator_color = "frame";

        sort = true;

        font = "LiterationSans book Nerd Font 12";

        line_height = 0;

        markup = "full";

        # The format of the message.  Possible variables are:
        #   %a  appname
        #   %s  summary
        #   %b  body
        #   %i  iconname (including its path)
        #   %I  iconname (without its path)
        #   %p  progress value if set ([  0%] to [100%]) or nothing
        #   %n  progress value if set without any extra characters
        #   %%  Literal %
        # Markup is allowed
        format = "<b>%s</b>\n%b";
        alignment = "left";
        show_age_threshold = 60;
        ellipsize = "middle";
        stack_duplicates = true;
        hide_duplicate_count = false;
        show_indicators = true;
        icon_position = "left";
        min_icon_size = 30;
        max_icon_size = 30;
        icon_theme = "Papirus, Adwaita";
        enable_recursive_icon_lookup = true;
        always_run_scripts = true;
        sticky_history = true;
        history_length = 20;
        browser = "/usr/bin/xdg-open";
        always_run_script = true;
        title = "Dunst";
        class = "Dunst";
        corner_radius = 10;
        ignore_dbusclose = false;

        mouse_left_click = [ "do_action" ];
        mouse_middle_click = [
          "context"
          "close_all"
        ];
        mouse_right_click = [
          "close_current"
          "close_current"
        ];
      };

      experimental = {
        per_monitor_dpi = false;
      };

      urgency_low = {
        background = "#0a0e14";
        foreground = "#bfbab0";
        frame_color = "#bae67e";
        timeout = 10;
      };

      urgency_normal = {
        background = "#0a0e14";
        foreground = "#bfbab0";
        frame_color = "#73d0ff";
        timeout = 10;
      };

      urgency_critical = {
        background = "#0a0e14";
        foreground = "#ff3333";
        frame_color = "#f26D78";
        timeout = 0;
      };
    };
  };
}
