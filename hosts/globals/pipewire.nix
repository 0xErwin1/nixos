{ pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    pulsemixer
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
          # mSBC (HFP codec 2) gives a 16 kHz headset mic instead of CVSD's
          # 8 kHz. It negotiates cleanly with the XM5; an earlier failure that
          # aborted the SCO transport turned out to be EasyEffects holding the
          # capture graph open, not mSBC itself.
          "bluez5.enable-msbc" = true;
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
          # Codec allow-list. This gates HFP codecs as well as A2DP ones, so
          # msbc must be listed here or `bluez5.enable-msbc` above has nothing
          # left to enable and the headset mic silently drops to 8 kHz CVSD.
          # CVSD needs no entry: it is the mandatory HFP baseline and stays
          # available as the fallback when mSBC negotiation fails.
          #
          # A2DP and HFP negotiate from separate candidate sets, so msbc does
          # not compete with the A2DP entries and its position is irrelevant.
          # Among the A2DP codecs order is priority, highest first: LDAC is
          # deliberately left out because its ~200-300 ms of latency desyncs
          # audio from video, and dropping it is what makes AAC the default.
          # Applies to every Bluetooth device, not just the XM5.
          "bluez5.codecs" = [
            "aac"
            "sbc_xq"
            "sbc"
            "msbc"
          ];
        };
        "wireplumber.settings" = {
          "bluetooth.autoswitch-to-headset-profile" = true;
        };
      };
    };
  };
}
