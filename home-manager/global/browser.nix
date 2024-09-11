{ pkgs, inputs, ... }:
{
  programs = {
    brave = {
      enable = true;
    };

    librewolf = {
      enable = true;
      settings = {
        "webgl.disabled" = false;
        "privacy.resistFingerprinting" = false;
        "privacy.clearOnShutdown.history" = false;
        "privacy.clearOnShutdown.cookies" = false;
        "privacy.clearHistory.cache" = false;
        "privacy.clearHistory.cookiesAndStorage" = false;
        "privacy.clearHistory.historyFormDataAndDownloads" = false;
        "privacy.clearOnShutdown_v2.cache" = false;
        "privacy.clearOnShutdown_v2.cookiesAndStorage" = false;
        "privacy.history.custom" = true;
        "network.cookie.lifetimePolicy" = 0;

        "identity.fxaccounts.enabled" = true;

        "sidebar.verticalTabs" = true;
        "sidebar.revamp" = true;
      };
    };

    firefox = {
      enable = true;
      package = pkgs.firefox-devedition-bin;
    };
  };

  xdg.mimeApps = {
    enable = true;
    defaultApplications = {
      "default-web-browser" = [ "librewolf.desktop" ];
      "text/html" = [ "librewolf.desktop" ];
      "x-scheme-handler/http" = [ "librewolf.desktop" ];
      "x-scheme-handler/https" = [ "librewolf.desktop" ];
      "x-scheme-handler/about" = [ "librewolf.desktop" ];
      "x-scheme-handler/unknown" = [ "librewolf.desktop" ];
    };

    associations.removed = {
      "default-web-browser" = [ "brave.desktop" ];
      "text/html" = [ "brave.desktop" ];
      "x-scheme-handler/http" = [ "brave.desktop" ];
      "x-scheme-handler/https" = [ "brave.desktop" ];
      "x-scheme-handler/about" = [ "brave.desktop" ];
      "x-scheme-handler/unknown" = [ "brave.desktop" ];
    };
  };
}
