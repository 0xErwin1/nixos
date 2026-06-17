{ pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    pulsemixer
    easyeffects
  ];

  services.pipewire = {
    enable = true;
    alsa = {
      enable = true;
      support32Bit = true;
    };
    pulse.enable = true;
    jack.enable = true;
    extraLv2Packages = with pkgs; [
      calf
      lsp-plugins
      mda_lv2
      rnnoise-plugin
      x42-plugins
      zam-plugins
    ];
    wireplumber = {
      enable = true;
      extraConfig."10-bluetooth" = {
        "monitor.bluez.properties" = {
          # mSBC (HFP codec 2) negotiation fails with XM5 on this system,
          # causing transport creation to fail and profile switch to abort.
          # Force CVSD (codec 1) for reliable HFP connections.
          "bluez5.enable-msbc" = false;
          # Explicit native backend to skip the oFono probe that logs errors
          # when oFono is not running.
          "bluez5.hfphsp-backend" = "native";
          # Without an explicit profile, the device idles to "off" after no audio.
          # When autoswitch tries to switch to HFP it looks for the current
          # non-headset profile as fallback — if profile is "off" it aborts with
          # "Could not find valid non-headset profile, not switching".
          # Keeping a2dp-sink active ensures the autoswitch always has a valid
          # profile to return to after a call.
          "bluez5.profile" = "a2dp-sink";
        };
        "wireplumber.settings" = {
          "bluetooth.autoswitch-to-headset-profile" = true;
        };
      };
    };
  };
}
