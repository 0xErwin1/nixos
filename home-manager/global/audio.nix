{ pkgs, ... }:
{
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

  home.packages = with pkgs; [
    vlc
    pavucontrol
  ];
}
