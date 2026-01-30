from os import path
import os
import subprocess
import re
import platform
from libqtile import bar, layout, widget, hook
from libqtile.config import Click, Drag, Group, Key, Match, Screen
from libqtile.lazy import lazy
from libqtile.log_utils import logger
from rules import rules


@hook.subscribe.startup_once
def autostart():
    subprocess.Popen([path.expanduser('~') + '/.config/qtile/autostart'])


mod = "mod4"

colors = {
    "yellow": "#FFB454",
    "brightYellow": "#131721",
    "orange": "#FF8F40",
    "blue": "#39BAE6",
    "green": "#AAD94C",
    "red": "#F26D78",
    "cyan": "#95E6CB",
    "grey": "#6C7380E6",
    "background": "#0D1017",
    "foreground": "#BFBDB6",
}

keys = [Key(key[0], key[1], *key[2:]) for key in [
    # Switch between windows in current stack pane
    ([mod], "j", lazy.layout.down()),
    ([mod], "k", lazy.layout.up()),
    ([mod], "h", lazy.layout.left()),
    ([mod], "l", lazy.layout.right()),

    # Move windows in current stack
    ([mod, "shift"], "h", lazy.layout.shuffle_left()),
    ([mod, "shift"], "l", lazy.layout.shuffle_right()),
    ([mod, "shift"], "j", lazy.layout.shuffle_down()),
    ([mod, "shift"], "k", lazy.layout.shuffle_up()),

    # Resize windows (Columns/Monad)
    (["mod1", "shift"], "h", lazy.layout.grow_left()),
    (["mod1", "shift"], "l", lazy.layout.grow_right()),
    (["mod1", "shift"], "j", lazy.layout.grow_down()),
    (["mod1", "shift"], "k", lazy.layout.grow_up()),

    # Toggle floating / fullscreen
    ([mod], "v", lazy.window.toggle_floating()),
    ([mod], "f", lazy.window.toggle_floating()),
    ([mod], "space", lazy.window.toggle_fullscreen()),

    # Toggle between last two groups quickly
    ([mod], "Tab", lazy.screen.toggle_group()),
    ([mod, "control"], "Tab", lazy.next_layout()),
    ([mod, "control", "shift"], "Tab", lazy.prev_layout()),

    # Kill window
    ([mod], "w", lazy.window.kill()),

    # Switch focus of monitors
    ([mod], "x", lazy.next_screen()),
    ([mod, "shift"], "x", lazy.prev_screen()),
    ([mod], "period", lazy.next_screen()),
    ([mod], "comma", lazy.prev_screen()),

    # Restart Qtile
    ([mod, "control"], "r", lazy.restart()),
    ([mod, "shift"], "q", lazy.shutdown()),

    # Menu
    ([mod], "m", lazy.spawn("wofi --show drun")),
    ([mod, "shift"], "m", lazy.spawn("wofi -show window")),

    # Browser
    ([mod], "b", lazy.spawn("zen-browser")),
    ([mod, "shift"], "b", lazy.spawn("firefox")),

    # File Explorer
    ([mod], "e", lazy.spawn("pcmanfm")),

    # Terminal
    ([mod], "Return", lazy.spawn("ghostty")),

    # Screenshot
    ([mod], "p", lazy.spawn(
        "grim -g \"$(slurp)\" - | satty --filename - --output-filename \"$HOME/Pictures/Screenshots/screenshot-$(date +'%Y-%m-%d_%H-%M-%S').png\" --early-exit --actions-on-enter save-to-clipboard --save-after-copy --copy-command 'wl-copy'")),

    ([mod, "control"], "l", lazy.spawn("hyprlock")),

    # ------------ Hardware Configs ------------

    # Volume
    ([], "XF86AudioLowerVolume", lazy.spawn(
        "wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"
    )),
    ([], "XF86AudioRaiseVolume", lazy.spawn(
        "wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+"
    )),
    ([], "XF86AudioMute", lazy.spawn(
        "wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"
    )),
    ([], "XF86AudioMicMute", lazy.spawn(
        "wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"
    )),

    # Brightness
    ([], "XF86MonBrightnessUp", lazy.spawn("brightnessctl -e4 -n2 set 5%+")),
    ([], "XF86MonBrightnessDown", lazy.spawn("brightnessctl -e4 -n2 set 5%-")),

    # Media keys
    ([], "XF86AudioNext", lazy.spawn("playerctl next")),
    ([], "XF86AudioPause", lazy.spawn("playerctl play-pause")),
    ([], "XF86AudioPlay", lazy.spawn("playerctl play-pause")),
    ([], "XF86AudioPrev", lazy.spawn("playerctl previous")),

    ([], "XF86NotificationCenter",
     lazy.spawn("dunstctl set-paused toggle")),
]]

groups = [
    Group("1", label=" ", layout="stack", matches=rules("1")),
    Group("2", label=" ", layout="stack", matches=rules("2")),
    Group("3", label=" ", layout="stack", matches=rules("3")),
    Group("4", label=" ", layout="stack", matches=rules("4")),
    Group("5", label=" ", layout="stack", matches=rules("5")),
    Group("6", label=" ", layout="stack", matches=rules("6")),
    Group("7", label=" ", layout="stack", matches=rules("7")),
    Group("8", label=" ", layout="stack", matches=rules("8")),
    Group("9", label=" ", layout="stack", matches=rules("9")),
    Group("10", label=" ", layout="stack", matches=rules("10")),
]

for group in groups:
    group_key = group.name
    if group_key == "10":
        group_key = "0"
    keys.extend([
        Key([mod], group_key, lazy.group[group.name].toscreen()),
        Key([mod, "shift"], group_key, lazy.window.togroup(group.name)),
    ])

layout_conf = {
    'border_focus': colors["green"],
    'border_normal': colors["blue"],
    'border_width': 3,
    'margin': 7
}

layouts = [
    layout.Max(**layout_conf),
    layout.Columns(**layout_conf),
    # layout.Floating(**layout_conf),
    # Try more layouts by unleashing below layouts.
    # layout.Bsp(),
    # layout.Matrix(),
    # layout.MonadTall(),
    # layout.MonadWide(),
    # layout.RatioTile(),
    # layout.Tile(),
    # layout.TreeTab(),
    # layout.VerticalTile(),
    # layout.Zoomy(),
]

widget_defaults = dict(
    font="LiterationMono Nerd Font",
    fontsize=12,
    padding=3,
)


def color_base():
    return {
        "foreground": colors["foreground"],
        "background": colors["background"],
    }


def icon(fg='text', bg='dark', fontsize=16, text="?"):
    return widget.TextBox(
        foreground=fg,
        background=bg,
        fontsize=fontsize,
        text=text,
        padding=3
    )


def distro(regex: str):
    return True if re.search(regex, platform.release()) else False


distro_icons = {
    "fedora": "  ",
    "arch": "  ",
    "linux": "  "
}


def distro_text():
    font_size = 16
    if distro("fc[0-9][0-9]"):
        return icon(colors["blue"], colors["background"], font_size, distro_icons["fedora"])
    if distro("arch"):
        return icon(colors["blue"], colors["background"], font_size, distro_icons["arch"])
    else:
        return icon(colors["blue"], colors["background"], font_size, distro_icons["linux"])


second_bar = bar.Bar([
    distro_text(),

    widget.GroupBox(
        **color_base(),
        font="LiterationMono Nerd Font",
        fontsize=16,
        margin_y=3,
        margin_x=0,
        padding_y=8,
        padding_x=5,
        borderwidth=1,
        active=colors["yellow"],
        inactive=colors['grey'],
        rounded=False,
        highlight_method='line',
        urgent_alert_method='block',
        urgent_border=colors['red'],
        this_current_screen_border=colors['orange'],
        this_screen_border=colors['grey'],
        other_current_screen_border=colors['background'],
        other_screen_border=colors['background'],
        disable_drag=True
    ),

    widget.Sep(**color_base(), linewidth=0, padding=5),

    widget.CurrentLayoutIcon(
        background=colors['background'],
        foreground=colors['orange'],
        scale=0.65
    ),

    widget.CurrentLayout(**color_base(), padding=5),

    widget.Sep(**color_base(), linewidth=0, padding=5),

    widget.WindowName(**color_base()),

    widget.Sep(**color_base(), linewidth=0, padding=5),

    widget.TextBox(
        foreground=colors["yellow"],
        background=colors["background"],
        fontsize=14,
        text=" ",
        padding=3
    ),

    widget.Backlight(
        background=colors['background'],
        foreground=colors['yellow'],
        backlight_name="intel_backlight",
        brightness_file="actual_brightness",
        fontsize=14,
    ),

    widget.Sep(**color_base(), linewidth=0, padding=5),

    widget.TextBox(
        foreground=colors["blue"],
        background=colors["background"],
        fontsize=14,
        text="墳",
        padding=3
    ),

    widget.PulseVolume(
        foreground=colors["blue"],
        background=colors["background"],
        fontsize=14,
        padding=5,
    ),

    widget.Sep(**color_base(), linewidth=0, padding=5),

    widget.TextBox(
        foreground=colors["orange"],
        background=colors["background"],
        fontsize=14,
        text=" ",
        padding=3
    ),

    widget.Battery(format=' {percent:2.0%}',
                   foreground=colors["orange"],
                   background=colors["background"],
                   fontsize=14,
                   padding=5,
                   ),

    widget.Sep(**color_base(), linewidth=0, padding=5),

    widget.TextBox(
        foreground=colors["cyan"],
        background=colors["background"],
        fontsize=16,
        text=" ",
        padding=3
    ),

    widget.Clock(
        foreground=colors["cyan"],
        background=colors["background"],
        format='%d/%m/%Y - %H:%M ',
        padding=5,
        fontsize=14,
    ),
], 24)


custom_bar = bar.Bar([
    distro_text(),

    widget.GroupBox(
        **color_base(),
        font="LiterationMono Nerd Font",
        fontsize=16,
        margin_y=3,
        margin_x=0,
        padding_y=8,
        padding_x=5,
        borderwidth=1,
        active=colors["yellow"],
        inactive=colors['grey'],
        rounded=False,
        highlight_method='line',
        urgent_alert_method='block',
        urgent_border=colors['red'],
        this_current_screen_border=colors['orange'],
        this_screen_border=colors['grey'],
        other_current_screen_border=colors['background'],
        other_screen_border=colors['background'],
        disable_drag=True
    ),

    widget.Sep(**color_base(), linewidth=0, padding=5),

    widget.CurrentLayoutIcon(
        background=colors['background'],
        foreground=colors['orange'],
        scale=0.65
    ),

    widget.CurrentLayout(**color_base(), padding=5),

    widget.Sep(**color_base(), linewidth=0, padding=5),

    widget.WindowName(**color_base()),

    widget.Sep(**color_base(), linewidth=0, padding=5),

    widget.TextBox(
        foreground=colors["yellow"],
        background=colors["background"],
        fontsize=14,
        text=" ",
        padding=3
    ),

    widget.Backlight(
        background=colors['background'],
        foreground=colors['yellow'],
        backlight_name="intel_backlight",
        brightness_file="actual_brightness",
        fontsize=14,
    ),

    widget.Sep(**color_base(), linewidth=0, padding=5),

    widget.TextBox(
        foreground=colors["blue"],
        background=colors["background"],
        fontsize=14,
        text="墳",
        padding=3
    ),

    widget.PulseVolume(
        foreground=colors["blue"],
        background=colors["background"],
        fontsize=14,
        padding=5,
    ),

    widget.Sep(**color_base(), linewidth=0, padding=5),

    widget.TextBox(
        foreground=colors["orange"],
        background=colors["background"],
        fontsize=14,
        text=" ",
        padding=3
    ),

    widget.Battery(format=' {percent:2.0%}',
                   foreground=colors["orange"],
                   background=colors["background"],
                   fontsize=14,
                   padding=5,
                   ),

    widget.Sep(**color_base(), linewidth=0, padding=5),

    widget.TextBox(
        foreground=colors["cyan"],
        background=colors["background"],
        fontsize=14,
        text=" ",
        padding=3
    ),

    widget.Clock(
        foreground=colors["cyan"],
        background=colors["background"],
        format='%d/%m/%Y - %H:%M ',
        padding=5,
        fontsize=14,
    ),

    widget.Systray(background=colors['background'], padding=5)
], 24)

screens = [
    Screen(
        top=custom_bar
    )
]

if os.environ.get("WAYLAND_DISPLAY"):
    output_count_cmd = "wlr-randr | awk '/^[^[:space:]]+/{count++} END {print count+0}'"
else:
    output_count_cmd = "xrandr | grep -w 'connected' | cut -d ' ' -f 2 | wc -l"

command = subprocess.run(
    output_count_cmd,
    shell=True,
    stdout=subprocess.PIPE,
    stderr=subprocess.PIPE,
)

if command.returncode != 0:
    error = command.stderr.decode("UTF-8")
    logger.error(f"Failed counting monitors using {output_count_cmd}:\n{error}")
    connected_monitors = 1
else:
    connected_monitors = int(command.stdout.decode("UTF-8"))

if connected_monitors > 1:
    for _ in range(1, connected_monitors):
        screens.append(Screen(top=second_bar))

# Drag floating layouts.
mouse = [
    Drag([mod], "Button1", lazy.window.set_position_floating(),
         start=lazy.window.get_position()),
    Drag([mod], "Button3", lazy.window.set_size_floating(),
         start=lazy.window.get_size()),
    Click([mod], "Button2", lazy.window.bring_to_front()),
]


floating_layout = layout.Floating(
    float_rules=rules(
        floating=True, layout_floating=layout.Floating.default_float_rules),
    border_focus=colors["yellow"]
)


main = None
dgroups_key_binder = None
dgroups_app_rules = []
follow_mouse_focus = True
bring_front_click = False
cursor_warp = True
auto_fullscreen = True
focus_on_window_activation = 'urgent'
wmname = 'LG3D'
