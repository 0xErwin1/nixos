{ pkgs, ... }:
{
  home.packages = with pkgs; [
    thunderbird
  ];

  programs = {
    brave = {
      enable = true;
    };

    librewolf = {
      enable = true;
      settings = {
        "webgl.disabled" = false;
        "privacy.resistFingerprinting" = true;
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
}
