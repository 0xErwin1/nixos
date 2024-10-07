let
  classFloat =
    "Lxapperance"
    + "Nitrogen"
    + "wpa_gui"
    + "Zathura"
    + "Places"
    + "Dialog"
    + "pop-up"
    + "Thunar"
    + "Pcmanfm"
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
    + "SpeedCrunch";

  peronsalBrowser = "firefox-nightly" + "LibreWolf";

  development = "";

  terminal = "";

  workBrowser = "firefoxdeveloperedition" + "firefox-aurora";

  file = "";

  db = "DBeaver";

  communication = "discord" + "Thunderbird";

  multimedia = "Spotify" + "Pulseaudio-equalizer-gtk" + "Pavucontrol" + "easyeffects";

  slack = "Slack";
in
{
  windowrulev1 = [ ];
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

    ## 5 - File

    ## 6 - DB
    "workspace 6, class:(${db})"

    ## 7 - Communication
    "workspace 7, class:(${communication})"

    ## 8 - Multimedia
    "workspace 8, class:(${multimedia})"

    ## 9 - Slack
    "workspace 9, class:(${slack})"
  ];
}
