{
  config,
  lib,
  pkgs,
  ...
}:
# Headless Chromium kept alive so agents can drive a real browser over the Chrome
# DevTools Protocol.
#
# The DevTools endpoint has no authentication whatsoever: reaching the port means
# arbitrary code execution and full access to the browser profile. It is therefore
# bound to loopback only and must never be moved to 0.0.0.0 or to the WireGuard
# address. Remote access goes through an SSH tunnel:
#   ssh -L 9222:127.0.0.1:9222 iperez@pi
let
  userDataDir = "${config.xdg.stateHome}/chromium-cdp";

  chromiumFlags = [
    "--headless=new"
    "--disable-gpu"
    "--no-first-run"
    "--remote-debugging-address=127.0.0.1"
    "--remote-debugging-port=9222"
    "--user-data-dir=${userDataDir}"
  ];
in
{
  home.packages = [ pkgs.chromium ];

  systemd.user.services.chromium-cdp = {
    Unit = {
      Description = "Headless Chromium with a loopback-only DevTools Protocol endpoint";
      After = [ "network.target" ];
    };

    Service = {
      Type = "simple";
      ExecStartPre = "${pkgs.coreutils}/bin/mkdir -p ${userDataDir}";
      ExecStart = "${pkgs.chromium}/bin/chromium ${lib.concatStringsSep " " chromiumFlags}";
      Restart = "on-failure";
      RestartSec = 5;
      Slice = "background.slice";
    };

    Install = {
      WantedBy = [ "default.target" ];
    };
  };
}
