{ pkgs, lib, ... }:
{
  hardware.bluetooth = {
    enable = true;
    settings = {
      General = {
        Experimental = "true";
      };
    };
  };
  services.blueman.enable = true;

  # NixOS generates a drop-in override for blueman-applet that adds ExecStart=
  # without first clearing the one already present in the package's unit file,
  # causing systemd to reject the service. Clear it explicitly before re-setting.
  systemd.user.services.blueman-applet = {
    overrideStrategy = "asDropin";
    serviceConfig = {
      ExecStart = lib.mkForce [
        ""
        "${pkgs.blueman}/bin/blueman-applet"
      ];
    };
  };
}
