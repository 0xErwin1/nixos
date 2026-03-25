{ pkgs, ... }:
{
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
      extraConfig."10-bluez-stability" = {
        "monitor.bluez.properties" = {
          "bluez5.enable-msbc" = true;
          "bluez5.enable-hw-volume" = true;
          "bluez5.roles" = [
            "a2dp_sink"
            "a2dp_source"
            "hsp_hs"
            "hsp_ag"
            "hfp_hf"
            "hfp_ag"
          ];
          "bluez5.hfphsp-backend" = "native";
          "bluez5.enable-sbc-xq" = true;
        };

        "wireplumber.settings" = {
          "bluetooth.autoswitch-to-headset-profile" = true;
          "bluetooth.use-persistent-storage" = true;
          "device.restore-profile" = true;
          "device.restore-routes" = true;
        };
      };
    };
  };
}
