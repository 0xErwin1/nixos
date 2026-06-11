{
  # The regular Brave package (programs.brave) ships brave-browser.desktop and
  # com.brave.Browser.desktop, both declaring MimeType= for web, image and xml
  # types. Any of those types without an explicit default here would let the
  # XDG resolver fall back to regular Brave. brave-origin-nightly is claimed
  # explicitly for every type Brave declares, and both regular-Brave desktop
  # files are removed as candidates for those same types.
  xdg.mimeApps =
    let
      braveOrigin = [ "brave-origin-nightly.desktop" ];
      thunderbirdMail = [ "userapp-Thunderbird-4SPX12.desktop" ];
      thunderbirdCalendar = [ "userapp-Thunderbird-EDTY12.desktop" ];

      regularBrave = [
        "brave-browser.desktop"
        "com.brave.Browser.desktop"
      ];

      # Exact MimeType= set declared by the regular Brave desktop files.
      regularBraveTypes = [
        "application/pdf"
        "application/rdf+xml"
        "application/rss+xml"
        "application/xhtml+xml"
        "application/xhtml_xml"
        "application/xml"
        "image/gif"
        "image/jpeg"
        "image/png"
        "image/webp"
        "text/html"
        "text/xml"
        "x-scheme-handler/http"
        "x-scheme-handler/https"
        "x-scheme-handler/chromium"
      ];
    in
    {
      enable = true;

      defaultApplications = {
        "default-web-browser" = braveOrigin;
        "text/html" = braveOrigin;
        "text/xml" = braveOrigin;
        "application/xhtml+xml" = braveOrigin;
        "application/xhtml_xml" = braveOrigin;
        "application/xml" = braveOrigin;
        "application/rdf+xml" = braveOrigin;
        "application/rss+xml" = braveOrigin;
        "image/gif" = braveOrigin;
        "image/jpeg" = braveOrigin;
        "image/png" = braveOrigin;
        "image/webp" = braveOrigin;
        "x-scheme-handler/http" = braveOrigin;
        "x-scheme-handler/https" = braveOrigin;
        "x-scheme-handler/about" = braveOrigin;
        "x-scheme-handler/unknown" = braveOrigin;
        "x-scheme-handler/chrome" = braveOrigin;
        "x-scheme-handler/chromium" = braveOrigin;

        "application/epub" = [ "org.pwmt.zathura.desktop" ];
        "application/pdf" = [ "org.pwmt.zathura.desktop" ];

        "text/calendar" = thunderbirdCalendar;
        "message/rfc822" = thunderbirdMail;
        "x-scheme-handler/mailto" = thunderbirdMail;
        "x-scheme-handler/mid" = thunderbirdMail;
        "x-scheme-handler/webcal" = thunderbirdCalendar;
        "application/x-extension-ics" = thunderbirdCalendar;
        "x-scheme-handler/webcals" = thunderbirdCalendar;

        "inode/directory" = [ "pcmanfm.desktop" ];
      };

      associations = {
        added = {
          "x-scheme-handler/tg" = [ "org.telegram.desktop.desktop" ];
          "x-scheme-handler/tonsite" = [ "org.telegram.desktop.desktop" ];
          "x-scheme-handler/mailto" = thunderbirdMail;
          "x-scheme-handler/mid" = thunderbirdMail;
          "x-scheme-handler/webcal" = thunderbirdCalendar;
          "x-scheme-handler/webcals" = thunderbirdCalendar;
        };

        removed = builtins.listToAttrs (
          map (type: {
            name = type;
            value = regularBrave;
          }) regularBraveTypes
        );
      };
    };
}
