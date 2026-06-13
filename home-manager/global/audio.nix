{ pkgs, lib, ... }:
{
  imports = [
    ./easyeffects-presets
  ];

  services.easyeffects.enable = true;

  # easyeffects connects to PipeWire via D-Bus on startup. Without explicit
  # ordering it can race against PipeWire/pipewire-pulse initialization and
  # stall the D-Bus session for several seconds. Force it to start after both
  # PipeWire services are ready.
  systemd.user.services.easyeffects = {
    Unit.After = [
      "pipewire.service"
      "pipewire-pulse.service"
    ];
    Unit.Wants = [
      "pipewire.service"
      "pipewire-pulse.service"
    ];

    # EasyEffects uses libadwaita. It does not support custom GTK themes like
    # palenight, only Adwaita light/dark. Disable portal theme probing and
    # force dark Adwaita for this service.
    Service.Environment = [
      "ADW_DISABLE_PORTAL=1"
      "GTK_THEME=Adwaita:dark"
    ];
  };

  # Keep EasyEffects processing playback (the output EQ) but stop it from
  # grabbing recording streams. On the WH-1000XM5 the headset cannot hold A2DP
  # and HFP at once: when EasyEffects attaches to the Bluetooth microphone the
  # call profile switch flaps and reverts to A2DP mid-call. Output processing
  # only touches the A2DP music path, so the EQ is unaffected.
  dconf.settings."org/gnome/easyeffects".process-all-inputs = false;

  home.packages = with pkgs; [
    vlc
    pavucontrol
  ];
}
