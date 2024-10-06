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
    "$mod, Shift+1, movetoworkspace, 1"
    "$mod, Shift+2, movetoworkspace, 2"
    "$mod, Shift+3, movetoworkspace, 3"
    "$mod, Shift+4, movetoworkspace, 4"
    "$mod, Shift+5, movetoworkspace, 5"
    "$mod, Shift+6, movetoworkspace, 6"
    "$mod, Shift+7, movetoworkspace, 7"
    "$mod, Shift+8, movetoworkspace, 8"
    "$mod, Shift+9, movetoworkspace, 9"
    "$mod, Shift+0, movetoworkspace, 10"
  ];

  menuBind = [
    "$mod, m, exec, rofi -show drun"
    "$mod, Shift, m, exec, rofi -show window"
  ];

  appBind = [
    "$mod, Return, exec, $terminal"
    "$mod, b, exec, $browser"
    "$mod, Shift, b, exec, $workBrowser"
    "$mod, s, exec, slack"
    "$mod, n, exec, obsidian"

    "$mod, p, exec, flameshot gui"
  ];

  bind = workspaceBind ++ menuBind ++ appBind;

  binde = [
    # Media Keys
    ", xf86audioraisevolume, exec, pamixer --increase 5"
    ", xf86audiolowervolume, exec, pamixer --decrease 5"
    ", xf86audiomute, exec, pamixer --toggle-mute"
    ", xf86audioplay, exec, playerctl play-pause"
    ", xf86audionext, exec, playerctl next"
    ", xf86audioprev, exec, playerctl previous"

    # Brightness Keys
    ", xf86monbrightnessup, exec, brightnessctl set +10%"
    ", xf86monbrightnessdown, exec, brightnessctl set 10%-"

    # Messenger Keys
    ", xf86messenger, exec, dunstctl set-paused toggle"
  ];
in
{
  inherit bind;
  inherit binde;
}
