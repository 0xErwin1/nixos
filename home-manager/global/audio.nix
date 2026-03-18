{ pkgs, lib, ... }:
{
  imports = [
    ./easyeffects-presets
  ];

  services.easyeffects.enable = true;

  # PipeWire low-latency configuration for multimedia (YouTube, videos, etc.)
  # The system-level config in hosts/epsilon/default.nix enables PipeWire.
  # This home-manager config tunes latency for better audio/video sync.
  #
  # Problem: Default quantum=1024 @ 48kHz = ~21ms latency causes A/V desync
  # Solution: quantum=256 @ 48kHz = ~5.3ms latency (good balance for multimedia)
  #
  # Note: Lower values (128, 64) can cause audio glitches on some systems.
  #       If you experience crackling, increase to 512 or back to 1024.
  xdg.configFile."pipewire/pipewire.conf.d/92-low-latency.conf".text = ''
    context.properties = {
      default.clock.rate = 48000
      default.clock.quantum = 256
      default.clock.min-quantum = 256
      default.clock.max-quantum = 512
    }
  '';

  xdg.configFile."pipewire/pipewire-pulse.conf.d/92-low-latency.conf".text = ''
    pulse.properties = {
      pulse.min.req = 256/48000
      pulse.default.req = 256/48000
      pulse.max.req = 512/48000
      pulse.min.quantum = 256/48000
      pulse.max.quantum = 512/48000
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
