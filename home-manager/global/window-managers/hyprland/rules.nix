let
  # Hyprland >= 0.53 (0.56.2 here) wants one `windowrule { ... }` block per rule,
  # with `name` as the first field, `match:*` selectors and snake_case rule
  # fields. `windowrulev1` no longer exists (silently ignored) and `windowrulev2`
  # is a config error. Class lists are joined with `|`: plain `+` would produce
  # one literal class name that never matches.
  classRegex = classes: "^(${builtins.concatStringsSep "|" classes})$";

  # Windows that should open floating.
  classFloat = [
    "Lxapperance"
    "nitrogen"
    "wpa_gui"
    "Places"
    "Dialog"
    "pop-up"
    "Thunar"
    "pcmanfm"
    "Piper"
    "Blueman-manager"
    "blueman-manager"
    "Blueman-adapter"
    "blueman-adapter"
    "NordPass"
    "Arandr"
    "Java"
    "TelegramDesktop"
    "whatsapp-nativefier-d40211"
    "whatsdesk"
    "Settings"
    "protonvpn"
    "cpupower-gui"
    "blueman-adapters"
    "SpeedCrunch"
    "swing-App"
    "Gcr-prompter"
    "Steam"
  ];

  personalBrowser = [
    "firefox-nightly"
    "floorp"
    "LibreWolf"
    "librewolf"
    "helium"
    "brave-origin-nightly"
  ];

  workBrowser = [
    "firefoxdeveloperedition"
    "firefox"
    "Google-chrome"
  ];

  db = [ "DBeaver" ];

  communication = [
    "TelegramDesktop"
    "Thunderbird"
    "zoom"
    "Zoom Cloud Meetings"
    "fluent-reader"
    "discord"
  ];

  multimedia = [
    "Spotify"
    "Pulseaudio-equalizer-gtk"
    "Pavucontrol"
  ];

  slack = [ "Slack" ];
in
{
  windowrule = [
    # Compositor-level fullscreen for RDR2, equivalent to
    # `hyprctl dispatch fullscreenstate 2 0`: Hyprland fills the monitor while
    # the game keeps running in windowed mode.
    {
      name = "rdr2-fullscreen";
      "match:class" = "^steam_app_1174180$";
      "match:title" = "^Red Dead Redemption 2$";
      fullscreen_state = "2 0";
    }

    # Float
    {
      name = "float-dialogs";
      "match:class" = classRegex classFloat;
      float = 1;
    }

    # Suppress maximize requests from every window.
    {
      name = "suppress-maximize";
      "match:class" = ".*";
      suppress_event = "maximize";
    }

    # Empty XWayland helper windows: keep them out of focus and out of layout.
    {
      name = "no-focus-empty-xwayland";
      "match:class" = "^$";
      "match:title" = "^$";
      "match:xwayland" = 1;
      "match:float" = 1;
      "match:fullscreen" = 0;
      "match:pin" = 0;
      no_focus = 1;
    }

    # Workspaces
    ## 1 - Personal Browser
    {
      name = "workspace-1-personal-browser";
      "match:class" = classRegex personalBrowser;
      workspace = 1;
    }

    ## 4 - Work Browser
    {
      name = "workspace-4-work-browser";
      "match:class" = classRegex workBrowser;
      workspace = 4;
    }

    ## 7 - DB
    {
      name = "workspace-7-db";
      "match:class" = classRegex db;
      workspace = 7;
    }

    ## 8 - Communication
    {
      name = "workspace-8-communication";
      "match:class" = classRegex communication;
      workspace = 8;
    }

    ## 9 - Multimedia
    {
      name = "workspace-9-multimedia";
      "match:class" = classRegex multimedia;
      workspace = 9;
    }

    ## 10 - Slack
    {
      name = "workspace-10-slack";
      "match:class" = classRegex slack;
      workspace = 10;
    }
  ];
}
