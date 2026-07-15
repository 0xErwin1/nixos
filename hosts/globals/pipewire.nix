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
          # Codec allow-list, highest priority first. LDAC is deliberately left
          # out: it has the best fidelity but ~200-300 ms of latency, enough to
          # desync audio from video. AAC keeps latency low at near-transparent
          # quality. WirePlumber always picks the highest-priority enabled codec,
          # so dropping LDAC here is what makes AAC the default. Applies to every
          # A2DP device, not just the XM5.
          "bluez5.codecs" = [
            "aac"
            "sbc_xq"
            "sbc"
          ];
        };
        "wireplumber.settings" = {
          "bluetooth.autoswitch-to-headset-profile" = true;
        };
      };
    };
  };
}
