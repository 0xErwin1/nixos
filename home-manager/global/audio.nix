{ pkgs, lib, ... }:
{
  imports = [
    ./easyeffects-presets
  ];

  services.easyeffects.enable = true;

  # PipeWire low-latency configuration for multimedia (YouTube, videos, etc.)
  # Keep a low default latency for A/V sync, but allow a higher runtime ceiling
  # so Bluetooth call profiles (HFP/HSP) can negotiate more stable buffer sizes.
  xdg.configFile."pipewire/pipewire.conf.d/92-low-latency.conf".text = ''
    context.properties = {
      default.clock.rate = 48000
      default.clock.quantum = 256
      default.clock.min-quantum = 256
      default.clock.max-quantum = 1024
    }
  '';

  xdg.configFile."pipewire/pipewire-pulse.conf.d/92-low-latency.conf".text = ''
    pulse.properties = {
      pulse.min.req = 256/48000
      pulse.default.req = 256/48000
      pulse.max.req = 1024/48000
      pulse.min.quantum = 256/48000
      pulse.max.quantum = 1024/48000
    }
    stream.properties = {
      node.latency = 256/48000
      resample.quality = 4
    }
  '';

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

  home.packages = with pkgs; [
    vlc
    pavucontrol
  ];
}
