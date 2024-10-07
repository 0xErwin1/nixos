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
  ];

  windowBind = [
    "$mod, L, moveFocus, l"
    "$mod, H, moveFocus, r"
    "$mod, K, moveFocus, u"
    "$mod, J, moveFocus, d"

    "$mod SHIFT, L, moveWindow, l"
    "$mod SHIFT, H, moveWindow, r"
    "$mod SHIFT, K, moveWindow, u"
    "$mod SHIFT, J, moveWindow, d"
  ];

  mouseBind = [
    "$mod, mouse:272, movewindow"
    "$mod, mouse:273, resizewindow"
  ];

  menuBind = [
    "$mod, M, exec, rofi -show drun"
    "$mod SHIFT, M, exec, rofi -show window"
  ];

  hyperBind = [
    "$mod, Q, exit"
    "$mod, W, killactive"
    "$mod, V, togglefloating"

    "$mod, Z, togglesplit"
  ];

  appBind = [
    "$mod, Return, exec, $terminal"
    "$mod, B, exec, $browser"
    "$mod SHIFT, B, exec, $workBrowser"
    "$mod, S, exec, slack"
    "$mod, N, exec, obsidian"

    "$mod, P, exec, flameshot gui"
  ];

  bindm = mouseBind;

  bind = hyperBind ++ workspaceBind ++ windowBind ++ menuBind ++ appBind;

  bindel = [
    # Media Keys
    ", XF86AudioRaiseVolume, exec, pamixer --increase 5"
    ", XF86AudioLowerVolume, exec, pamixer --decrease 5"
    ", XF86AudioMute, exec, pamixer --toggle-mute"
    ", XF86AudioPlay, exec, playerctl play-pause"
    ", XF86AudioPrev, exec, playerctl previous"
    ", XF86AudioNext, exec, playerctl next"

    # Brightness Keys
    ", XF86MonBrightnessUp, exec, brightnessctl set +10%"
    ", XF86MonBrightnessDown, exec, brightnessctl set 10%-"

    # Messenger Keys
    ", XF86Messenger, exec, dunstctl set-paused toggle"
  ];
in
{
  inherit bind;
  inherit bindel;
  inherit bindm;
}
