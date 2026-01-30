let
  workspaceBind = [
    "$mod, 1, workspace, 1"
    "$mod, 2, workspace, 2"
    "$mod, 3, workspace, 3"
    "$mod, 4, workspace, 4"
    "$mod, 5, workspace, 5"
    "$mod, 6, workspace, 6"
    "$mod, 7, workspace, 7"
    "$mod, 8, workspace, 8"
    "$mod, 9, workspace, 9"
    "$mod, 0, workspace, 10"
    "$mod SHIFT, 1, movetoworkspace, 1"
    "$mod SHIFT, 2, movetoworkspace, 2"
    "$mod SHIFT, 3, movetoworkspace, 3"
    "$mod SHIFT, 4, movetoworkspace, 4"
    "$mod SHIFT, 5, movetoworkspace, 5"
    "$mod SHIFT, 6, movetoworkspace, 6"
    "$mod SHIFT, 7, movetoworkspace, 7"
    "$mod SHIFT, 8, movetoworkspace, 8"
    "$mod SHIFT, 9, movetoworkspace, 9"
    "$mod SHIFT, 0, movetoworkspace, 10"

    # Special workspace (scratchpad)
    "$mod, S, togglespecialworkspace, magic"
    "$mod SHIFT, S, movetoworkspace, special:magic"

    # Scroll through workspaces
    "$mod, mouse_down, workspace, e+1"
    "$mod, mouse_up, workspace, e-1"
  ];

  windowBind = [
    "$mod, H, movefocus, l"
    "$mod, L, movefocus, r"
    "$mod, K, movefocus, u"
    "$mod, J, movefocus, d"

    "$mod SHIFT, H, movewindow, l"
    "$mod SHIFT, L, movewindow, r"
    "$mod SHIFT, K, movewindow, u"
    "$mod SHIFT, J, movewindow, d"

    # Resize active window (ALT+SHIFT+HJKL)
    "ALT SHIFT, H, resizeactive, -20 0"
    "ALT SHIFT, L, resizeactive, 20 0"
    "ALT SHIFT, J, resizeactive, 0 20"
    "ALT SHIFT, K, resizeactive, 0 -20"
  ];

  mouseBind = [
    "$mod, mouse:272, movewindow"
    "$mod, mouse:273, resizewindow"
  ];

  menuBind = [
    "$mod, M, exec, wofi -show drun"
    "$mod SHIFT, M, exec, wofi -show window"
  ];

  hyperBind = [
    "$mod SHIFT, Q, exit"
    "$mod, W, killactive"
    "$mod, V, togglefloating"
    "$mod, F, togglefloating"

    "$mod, Z, pseudo"
    "$mod, Tab, togglesplit"
    "$mod, Space, fullscreen, 1"
  ];

  appBind = [
    "$mod, Return, exec, $terminal"
    "$mod, E, exec, $fileManager"
    "$mod, B, exec, $browser"
    "$mod SHIFT, B, exec, $workBrowser"

    "$mod, P, exec, $screenshot"
    "$mod Control, L, exec, hyprlock"
  ];

  bindm = mouseBind;

  bind = hyperBind ++ workspaceBind ++ windowBind ++ menuBind ++ appBind;

  # Volume/brightness/notifications (repeatable)
  bindel = [
    ", XF86AudioRaiseVolume, exec, wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+"
    ", XF86AudioLowerVolume, exec, wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"
    ", XF86AudioMute, exec, wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"
    ", XF86AudioMicMute, exec, wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"
    ", XF86MonBrightnessUp, exec, brightnessctl -e4 -n2 set 5%+"
    ", XF86MonBrightnessDown, exec, brightnessctl -e4 -n2 set 5%-"
    ", XF86NotificationCenter, exec, dunstctl set-paused toggle"
  ];

  # Media controls (work on lockscreen)
  bindl = [
    ", XF86AudioNext, exec, playerctl next"
    ", XF86AudioPause, exec, playerctl play-pause"
    ", XF86AudioPlay, exec, playerctl play-pause"
    ", XF86AudioPrev, exec, playerctl previous"
  ];
in
{
  inherit bind;
  inherit bindel;
  inherit bindm;
  inherit bindl;
}
