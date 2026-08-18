{ config, pkgs, ... }:
# The host side of Moshi, the phone terminal that attaches to this machine.
#
# The agent hooks it installs into the coding clients are not here: they are
# declared through the AI harness, in ai-harness-gentle-ai.nix, because they
# land in files the harness also writes.
{
  home.packages = [ pkgs.moshi-hook ];

  systemd.user.services.moshi-hook = {
    Unit = {
      Description = "Moshi hook daemon";
      After = [ "network-online.target" ];
    };

    Service = {
      ExecStart = "${pkgs.moshi-hook}/bin/moshi-hook serve";
      Restart = "on-failure";
      RestartSec = 5;
      WorkingDirectory = "%h";

      # The daemon shells out to whatever multiplexer a session is running
      # under, and a systemd user unit inherits almost no PATH. Upstream's own
      # unit names /usr/bin and /bin, which on this machine hold nothing it
      # needs.
      Environment = [
        "PATH=${config.home.profileDirectory}/bin:/run/current-system/sw/bin"
      ];
    };

    Install.WantedBy = [ "default.target" ];
  };
}
