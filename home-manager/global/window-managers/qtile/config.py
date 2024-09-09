from os import path
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
    subprocess.Popen([path.expanduser('~') + '/.config/qtile/autostart.sh'])


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

    # Change window sizes (MonadTall)
    ([mod, "shift"], "l", lazy.layout.grow()),
    ([mod, "shift"], "h", lazy.layout.shrink()),

    # Toggle floating
    ([mod, "shift"], "f", lazy.window.toggle_floating()),

    # Move windows up or down in current stack
    ([mod, "shift"], "j", lazy.layout.shuffle_down()),
    ([mod, "shift"], "k", lazy.layout.shuffle_up()),

    # Toggle between different layouts as defined below
    ([mod], "Tab", lazy.next_layout()),
    ([mod, "shift"], "Tab", lazy.prev_layout()),

    # Kill window
    ([mod], "w", lazy.window.kill()),

    # Switch focus of monitors
    ([mod], "period", lazy.next_screen()),
    ([mod], "comma", lazy.prev_screen()),

    # Restart Qtile
    ([mod, "control"], "r", lazy.restart()),

    ([mod, "control"], "q", lazy.shutdown()),

    # Menu
    ([mod], "m", lazy.spawn("rofi -show drun")),

    # Window Nav
    ([mod, "shift"], "m", lazy.spawn("rofi -show")),

    # Browser
    ([mod], "b", lazy.spawn("firefox-developer-edition")),
    ([mod, "shift"], "b", lazy.spawn("google-chrome")),

    # File Explorer
    ([mod], "e", lazy.spawn("pcmanfm")),

    # Terminal
    ([mod], "Return", lazy.spawn("alacritty")),
    ([mod, "shift"], "Return", lazy.spawn("tilix")),

    # Redshif
    ([mod], "r", lazy.spawn("redshift -O 5000")),
    ([mod, "shift"], "r", lazy.spawn("redshift -x")),

    # Screenshot
    ([mod], "s", lazy.spawn(
        "scrot -s 'screenshot_%Y-%m-%d-%T_$wx$h.png' -e 'mkdir -p ~/Pictures/screenshots/ | mv $f ~/Pictures/screenshots/'")),

    ([mod, "control"], "l", lazy.spawn("betterlockscreen -l blur")),

    # ------------ Hardware Configs ------------

    # Volume
    ([], "XF86AudioLowerVolume", lazy.spawn(
        "pactl set-sink-volume @DEFAULT_SINK@ -5%"
    )),
    ([], "XF86AudioRaiseVolume", lazy.spawn(
        "pactl set-sink-volume @DEFAULT_SINK@ +5%"
    )),
    ([], "XF86AudioMute", lazy.spawn(
        "pactl set-sink-mute @DEFAULT_SINK@ toggle"
    )),
    ([], "XF86AudioMute", lazy.spawn(
        "pactl set-sink-mute @DEFAULT_SINK@ toggle"
    )),

    # Brightness
    ([], "XF86MonBrightnessUp", lazy.spawn("brightnessctl set +10%")),
    ([], "XF86MonBrightnessDown", lazy.spawn("brightnessctl set 10%-")),
]]

groups = [Group(i, layout="stack", matches=rules(i)) for i in [
    " ", " ", " ", " ", " ", " ", " ", " ", " ",
]]

for i, group in enumerate(groups):
    actual_key = str(i + 1)
    keys.extend([
        Key([mod], actual_key, lazy.group[group.name].toscreen()),
        Key([mod, "shift"], actual_key, lazy.window.togroup(group.name))
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

xrandr = "xrandr | grep -w 'connected' | cut -d ' ' -f 2 | wc -l"

command = subprocess.run(
    xrandr,
    shell=True,
    stdout=subprocess.PIPE,
    stderr=subprocess.PIPE,
)

if command.returncode != 0:
    error = command.stderr.decode("UTF-8")
    logger.error(f"Failed counting monitors using {xrandr}:\n{error}")
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
