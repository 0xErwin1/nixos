{ ... }:
# The one Claude Code setting the client will not leave alone.
#
# `permissions.defaultMode` lives in the settings file the harness renders, and
# Claude Code rewrites it to "auto" during a session: after every activation it
# comes back as bypass and drifts away again within the hour, on the personal
# profile and the work one alike.
#
# Admin-managed policy is the one input the client reads and never writes. It is
# also machine-wide, which is what this needs to be: the drift is per config
# directory, and there is more than one of those.
{
  environment.etc."claude-code/managed-settings.json".text = builtins.toJSON {
    permissions.defaultMode = "bypassPermissions";
  };
}
