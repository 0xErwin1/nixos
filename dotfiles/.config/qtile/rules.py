from libqtile import layout
from libqtile.config import Match


def rules(group=None, floating=False, layout_floating=None):
    if not floating:
        rules_by_group = {
            "1": Match(wm_class=[
                "firefox-nightly",
                "floorp",
                "LibreWolf",
                "librewolf",
                "zen-browser",
            ]),
            "2": None,
            "3": None,
            "4": Match(wm_class=[
                "firefoxdeveloperedition",
                "firefox",
                "Google-chrome",
            ]),
            "5": None,
            "6": Match(wm_class=["Thunar", "pcmanfm"]),
            "7": Match(wm_class=["DBeaver"]),
            "8": Match(wm_class=[
                "TelegramDesktop",
                "Thunderbird",
                "zoom",
                "Zoom",
                "Zoom Cloud Meetings",
                "fluent-reader",
                "discord",
            ]),
            "9": Match(wm_class=[
                "Spotify",
                "spotify",
                "Pavucontrol",
                "Pulseaudio-equalizer-gtk",
            ]),
            "10": Match(wm_class=["Slack"]),
        }
        return rules_by_group.get(group)
    elif floating:
        if layout_floating is None:
            layout_floating = []
        return [
            *layout_floating,
            Match(wm_class='confirmreset'),  # gitk
            Match(wm_class='makebranch'),  # gitk
            Match(wm_class='maketag'),  # gitk
            Match(wm_class='ssh-askpass'),  # ssh-askpass
            Match(title='branchdialog'),  # gitk
            Match(wm_class='wpa_gui'),
            Match(wm_class='SpeedCrunch'),
            Match(wm_class='Nitrogen'),
            Match(wm_class='Lxappearance'),
            Match(wm_class='Lxapperance'),
            Match(wm_class='Zathura'),
            Match(wm_class='pavucontrol'),
            Match(wm_class='pulseaudio-equalizer-gtk'),
            Match(wm_class='Piper'),
            Match(wm_class='Postman'),
            Match(wm_class='Arandr'),
            Match(wm_class='NordPass'),
            Match(wm_class='Blueman-manager'),
            Match(wm_class='blueman-manager'),
            Match(wm_class='Blueman-adapter'),
            Match(wm_class='blueman-adapter'),
            Match(wm_class='blueman-adapters'),
            Match(wm_class='TelegramDesktop'),
            Match(wm_class='whatsapp-nativefier-d40211'),
            Match(wm_class='whatsdesk'),
            Match(wm_class='Settings'),
            Match(wm_class='protonvpn'),
            Match(wm_class='cpupower-gui'),
            Match(wm_class='swing-App'),
            Match(wm_class='Gcr-prompter'),
            Match(wm_class='Steam'),
            Match(wm_class='Lxpolkit'),
            Match(wm_class='Java'),
            Match(wm_class='Places'),
            Match(wm_class='Dialog'),
            Match(wm_class='pop-up'),
            Match(wm_class='firefox', wm_type='Dialog'),
            Match(wm_class='firefox', wm_type='Places'),
            Match(wm_class='firefox-developer-edition', wm_type='Dialog'),
            Match(wm_class='firefox-developer-edition', wm_type='Places'),
            Match(wm_class='Brave-browser', wm_type='Places'),
            Match(wm_class='Brave-browser', wm_type='pop-up'),
            Match(wm_class='Brave-browser-beta', wm_type='Places'),
            Match(wm_class='Brave-browser-beta', wm_type='pop-up'),
            Match(wm_class='Google-chrome', wm_type='Places'),
            Match(wm_class='Google-chrome', wm_type='pop-up'),
            Match(wm_class='Thunar', wm_type='Dialog'),
        ]
