{
  xdg.mimeApps = {
    enable = true;
    defaultApplications = {
      "default-web-browser" = [ "helium.desktop" ];
      "text/html" = [ "helium.desktop" ];
      "x-scheme-handler/http" = [ "helium.desktop" ];
      "x-scheme-handler/https" = [ "helium.desktop" ];
      "x-scheme-handler/about" = [ "helium.desktop" ];
      "x-scheme-handler/unknown" = [ "helium.desktop" ];
      "x-scheme-handler/chrome" = [ "helium.desktop" ];
      "application/epub" = [ "org.pwmt.zathura.desktop" ];
      "application/pdf" = [ "org.pwmt.zathura.desktop" ];
      "text/calendar" = [ "userapp-Thunderbird-EDTY12.desktop" ];
      "message/rfc822" = [ "userapp-Thunderbird-4SPX12.desktop" ];
      "x-scheme-handler/mailto" = [ "userapp-Thunderbird-4SPX12.desktop" ];
      "x-scheme-handler/mid" = [ "userapp-Thunderbird-4SPX12.desktop" ];
      "x-scheme-handler/webcal" = [ "userapp-Thunderbird-EDTY12.desktop" ];
      "application/x-extension-ics" = [ "userapp-Thunderbird-EDTY12.desktop" ];
      "x-scheme-handler/webcals" = [ "userapp-Thunderbird-EDTY12.desktop" ];
      "inode/directory" = [ "pcmanfm.desktop" ];
    };

    associations = {
      added = {
        "x-scheme-handler/tg" = [ "org.telegram.desktop.desktop" ];
        "x-scheme-handler/tonsite" = [ "org.telegram.desktop.desktop" ];
        "x-scheme-handler/mailto" = [ "userapp-Thunderbird-4SPX12.desktop" ];
        "x-scheme-handler/mid" = [ "userapp-Thunderbird-4SPX12.desktop" ];
        "x-scheme-handler/webcal" = [ "userapp-Thunderbird-EDTY12.desktop" ];
        "x-scheme-handler/webcals" = [ "userapp-Thunderbird-EDTY12.desktop" ];
      };
      removed = {
        "default-web-browser" = [ "brave.desktop" ];
        "text/html" = [ "brave.desktop" ];
        "image/svg+xml" = [ "brave.desktop" ];
        "image/x-icon" = [ "brave.desktop" ];
        "image/gif" = [ "brave.desktop" ];
        "image/jpeg" = [ "brave.desktop" ];
        "image/png" = [ "brave.desktop" ];
        "image/jpg" = [ "brave.desktop" ];
        "application/epub" = [ "brave.desktop" ];
        "application/pdf" = [ "brave.desktop" ];
        "application/x-extension-html" = [ "brave.desktop" ];
        "application/x-extension-htm" = [ "brave.desktop" ];
        "application/x-extension-xhtml" = [ "brave.desktop" ];
        "application/x-extension-xht" = [ "brave.desktop" ];
        "application/x-extension-xml" = [ "brave.desktop" ];
        "application/x-extension-rss" = [ "brave.desktop" ];
        "application/x-extension-atom" = [ "brave.desktop" ];
        "x-scheme-handler/http" = [ "brave.desktop" ];
        "x-scheme-handler/https" = [ "brave.desktop" ];
        "x-scheme-handler/about" = [ "brave.desktop" ];
        "x-scheme-handler/unknown" = [ "brave.desktop" ];
        "x-scheme-handler/chrome" = [ "brave.desktop" ];
      };
    };
  };
}
