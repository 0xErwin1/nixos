{ pkgs, ... }:
let
  python = pkgs.python3.withPackages (ps: [ ps.pygobject3 ]);
  monitor = pkgs.writeText "phone-automount.py" ''
    import gi

    gi.require_version("Gio", "2.0")
    from gi.repository import Gio, GLib


    class PhoneAutomount:
        def __init__(self, monitor):
            self.monitor = monitor
            self.pending = set()
            monitor.connect("volume-added", self.on_volume)
            monitor.connect("volume-changed", self.on_volume)
            for volume in monitor.get_volumes():
                self.mount(volume)

        def on_volume(self, monitor, volume):
            self.mount(volume)

        def mount(self, volume):
            root = volume.get_activation_root()
            if root is None or root.get_uri_scheme() not in ("mtp", "afc"):
                return
            if volume in self.pending or volume.get_mount() is not None or not volume.can_mount():
                return
            self.pending.add(volume)
            try:
                volume.mount(
                    Gio.MountMountFlags.NONE,
                    Gio.MountOperation.new(),
                    None,
                    self.on_mounted,
                    None,
                )
            except GLib.Error as error:
                self.pending.discard(volume)
                print(f"Phone mount failed: {error}", flush=True)

        def on_mounted(self, volume, result, user_data):
            try:
                volume.mount_finish(result)
                print("Phone volume mounted", flush=True)
            except GLib.Error as error:
                print(f"Phone mount failed: {error}", flush=True)
            finally:
                self.pending.discard(volume)


    if __name__ == "__main__":
        automount = PhoneAutomount(Gio.VolumeMonitor.get())
        GLib.MainLoop().run()
  '';
in
{
  # Mount only GVFS phone volumes, without owning interactive file-manager
  # preferences or competing with udiskie for generic removable drives.
  # Failed mounts retry only on subsequent volume events, never on a timer.
  systemd.user.services.phone-automount = {
    Unit = {
      Description = "Mount MTP and AFC phone volumes through GVFS";
      After = [ "graphical-session-pre.target" ];
      PartOf = [ "graphical-session.target" ];
    };
    Service = {
      Environment = [
        "GI_TYPELIB_PATH=${pkgs.glib.out}/lib/girepository-1.0"
        # The standalone Python process does not inherit a GTK application's
        # wrapped GVFS module path; without it, phone volumes are invisible.
        "GIO_EXTRA_MODULES=${pkgs.gvfs}/lib/gio/modules:${pkgs.dconf.lib}/lib/gio/modules"
      ];
      ExecStart = "${python}/bin/python ${monitor}";
      Restart = "on-failure";
      RestartSec = 3;
    };
    Install.WantedBy = [ "graphical-session.target" ];
  };
}
