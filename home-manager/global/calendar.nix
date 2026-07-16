{ pkgs, ... }:
# Calendar backend for the Astal bar's calendar panel.
#
# The bar reads events by shelling out to `khal`, configured here to DISCOVER
# every vdir under ~/.calendars — so any calendar synced there appears
# automatically without editing this file. A local "personal" calendar is
# created so khal is usable out of the box (and `khal new` has a default).
#
# Remote calendars (Nextcloud, Google, iCloud — any CalDAV) are synced into
# ~/.calendars with vdirsyncer, which is installed here but intentionally NOT
# configured in the repo: its config carries per-account URLs and app-password
# commands (secrets must not live in version control). Set it up once, outside
# git, in ~/.config/vdirsyncer/config:
#
#   [general]
#   status_path = "~/.local/share/vdirsyncer/status/"
#
#   [pair nextcloud]
#   a = "nextcloud_local"
#   b = "nextcloud_remote"
#   collections = ["from a", "from b"]
#   metadata = ["displayname", "color"]
#
#   [storage nextcloud_local]
#   type = "filesystem"
#   path = "~/.calendars/"
#   fileext = ".ics"
#
#   [storage nextcloud_remote]
#   type = "caldav"
#   url = "https://cloud.example.com/remote.php/dav/"
#   username = "you"
#   password.fetch = ["command", "pass", "nextcloud/caldav"]  # app password, out of the file
#
# Then run `vdirsyncer discover && vdirsyncer sync` (a systemd user timer keeps
# it in sync). Google uses an OAuth client instead of a password — see the
# vdirsyncer "google_calendar" storage type.
{
  home.packages = [
    pkgs.khal
    pkgs.vdirsyncer
  ];

  # A local vdir so khal always has a valid, writable calendar even before any
  # remote account is configured.
  home.file.".calendars/personal/.keep".text = "";

  xdg.configFile."khal/config".text = ''
    [calendars]

    [[discovered]]
    path = ~/.calendars/*
    type = discover

    [locale]
    timeformat = %H:%M
    dateformat = %Y-%m-%d
    longdateformat = %Y-%m-%d
    datetimeformat = %Y-%m-%d %H:%M
    longdatetimeformat = %Y-%m-%d %H:%M
    firstweekday = 0

    [default]
    default_calendar = personal
  '';
}
