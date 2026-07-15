{ pkgs, ... }:
# The herdr server owns the live agent panes; clients only attach to it. Running
# it as a lingering user service is what guarantees `herdr --remote ssh://iperez@pi`
# always finds a server, including right after an unattended reboot.
#
# It is deliberately not pinned to background.slice: the panes it hosts are
# interactive, so it must keep the default CPU weight and stay ahead of the
# build and background slices.
{
  systemd.user.services.herdr-server = {
    Unit = {
      Description = "Herdr headless server for remote agent sessions";
    };

    Service = {
      Type = "simple";
      ExecStart = "${pkgs.herdr}/bin/herdr server";
      ExecStop = "${pkgs.herdr}/bin/herdr server stop";
      Restart = "on-failure";
      RestartSec = 5;
    };

    Install = {
      WantedBy = [ "default.target" ];
    };
  };
}
