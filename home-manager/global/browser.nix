{ pkgs, inputs, ... }:
{
  imports = [
    inputs.zenBrowserFlake.homeModules.beta
  ];

  home.packages = with pkgs; [
    thunderbird
    helium
  ];

  programs = {
    brave = {
      enable = true;
      commandLineArgs = [
        "--ozone-platform=x11"
        "--use-gl=desktop"
        "--disable-features=Vulkan"
      ];
    };

    librewolf = {
      enable = false;
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
    };

    zen-browser = {
      enable = false;
      policies = {
        AutofillAddressEnabled = true;
        AutofillCreditCardEnabled = false;
        DisableAppUpdate = true;
        DisableFeedbackCommands = true;
        DisableFirefoxStudies = true;
        DisablePocket = true;
        DisableTelemetry = true;
        DontCheckDefaultBrowser = true;
        NoDefaultBookmarks = true;
        OfferToSaveLogins = false;
        EnableTrackingProtection = {
          Value = true;
          Locked = true;
          Cryptomining = true;
          Fingerprinting = true;
        };
      };
    };
  };
}
