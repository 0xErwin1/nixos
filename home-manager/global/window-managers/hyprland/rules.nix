let
  classFloat =
    "Lxapperance"
    + "nitrogen"
    + "wpa_gui"
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
    + "blueman-adapters";

  peronsalBrowser = "firefox-nightly" + "LibreWolf" + "zen-browser";

  development = "";

  terminal = "";

  workBrowser = "firefoxdeveloperedition" + "firefox-aurora" + "firefox";

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
