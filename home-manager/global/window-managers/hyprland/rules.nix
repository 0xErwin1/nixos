let
  classFloat =
    "Lxapperance"
    + "nitrogen"
    + "wpa_gui"
    + "Places"
    + "Dialog"
    + "pop-up"
    + "Thunar"
    + "pcmanfm"
    + "Piper"
    + "Blueman-manager"
    + "blueman-manager"
    + "Blueman-adapter"
    + "blueman-adapter"
    + "NordPass"
    + "Arandr"
    + "Java"
    + "TelegramDesktop"
    + "whatsapp-nativefier-d40211"
    + "whatsdesk"
    + "Settings"
    + "protonvpn"
    + "cpupower-gui"
    + "blueman-adapters"
    + "SpeedCrunch"
    + "swing-App"
    + "Gcr-prompter"
    + "Steam";

  peronsalBrowser = "firefox-nightly" + "floorp" + "LibreWolf" + "librewolf" + "zen-browser";

  development = "";

  terminal = "";

  workBrowser = "firefoxdeveloperedition" + "firefox" + "Google-chrome";

  file = "";

  db = "DBeaver";

  communication = "TelegramDesktop" + "Thunderbird" + "zoom" + "Zoom Cloud Meetings" + "fluent-reader" + "discord";

  multimedia = "Spotify" + "Pulseaudio-equalizer-gtk" + "Pavucontrol" + "easyeffects";

  slack = "Slack";
in
{
  windowrulev1 = [
    "suppressevent maximize, class:.*"
    "nofocus,class:^$,title:^$,xwayland:1,floating:1,fullscreen:0,pinned:0"
  ];
  windowrulev2 = [
    # Float
    "float, class:(${classFloat})"

    # Workspaces
    ## 1 - Personal Browser
    "workspace 1, class:(${peronsalBrowser})"

    ## 2 - Development

    ## 3 - Terminal

    ## 4 - Work Browser
    "workspace 4, class:(${workBrowser})"

    ## 5 - Config

    ## 6 - File

    ## 7 - DB
    "workspace 7, class:(${db})"

    ## 8 - Communication
    "workspace 8, class:(${communication})"

    ## 9 - Multimedia
    "workspace 9, class:(${multimedia})"

    ## 10 - Slack
    "workspace 10, class:(${slack})"
  ];
}
