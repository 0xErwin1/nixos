import Gio from "gi://Gio";
import GLib from "gi://GLib";
import AstalNotifd from "gi://AstalNotifd";
import { createState } from "ags";

import {
  NotificationHistory,
  isFilePath,
  type Group,
  type Incoming,
  type Urgency,
} from "./notify-history";

// Instantiating the daemon acquires the org.freedesktop.Notifications bus name
// (only if free — dunst must be gone), making the bar the notification server.
export const notifd = AstalNotifd.get_default();

// Keep notifications alive until the user dismisses them. By default the daemon
// closes each one when its expire timeout elapses, which would also take away
// the live object the center invokes actions on. The transient popup is still
// hidden on its own timer below.
notifd.ignoreTimeout = true;

// The center reads the bar's own history, not notifd.notifications: the daemon
// overwrites a notification sent with `replaces_id`, which is how every message
// after the first one of a WhatsApp Web chat arrives. Unbounded history freezes
// the bar over long sessions, so the store caps count and age.
const history = new NotificationHistory({
  maxStored: 50,
  // Drop anything older than 12h from the center even if the user never cleared.
  maxAgeSeconds: 12 * 3600,
  // Teams and Slack sometimes deliver one message as two notifications at
  // once. Only an identical arrival this close collapses; a later run of the
  // same command (another screenshot, the next AI usage alert) is kept.
  duplicateWindowMs: 1000,
});
const PRUNE_INTERVAL_SECONDS = 120;

// Chromium writes a web notification's icon and image into a scoped temporary
// directory and deletes it when the notification closes, which WhatsApp Web
// does before every new message. The history outlives that, so each file is
// copied here on arrival, named by content hash so a repeated avatar is
// stored once, and removed once no stored message shows it.
const IMAGE_CACHE = GLib.build_filenamev([GLib.get_user_cache_dir(), "wl-bar", "notifications"]);
GLib.mkdir_with_parents(IMAGE_CACHE, 0o700);

function keepFile(src: string): string {
  if (!isFilePath(src)) return src;
  const path = src.replace(/^file:\/\//, "");
  if (path.startsWith(IMAGE_CACHE + "/")) return path;
  try {
    const [, bytes] = Gio.File.new_for_path(path).load_contents(null);
    const hash = GLib.compute_checksum_for_data(GLib.ChecksumType.SHA256, bytes);
    const dot = path.lastIndexOf(".");
    const ext = dot > path.lastIndexOf("/") ? path.slice(dot) : "";
    const copy = GLib.build_filenamev([IMAGE_CACHE, `${hash}${ext}`]);
    if (!GLib.file_test(copy, GLib.FileTest.EXISTS)) {
      GLib.file_set_contents(copy, bytes);
    }
    return copy;
  } catch {
    // Already deleted by its sender, or unreadable: keep the original path.
    return src;
  }
}

function sweepImageCache(): void {
  const keep = history.referencedFiles();
  try {
    const children = Gio.File.new_for_path(IMAGE_CACHE).enumerate_children(
      "standard::name",
      Gio.FileQueryInfoFlags.NONE,
      null,
    );
    let info: Gio.FileInfo | null;
    while ((info = children.next_file(null)) !== null) {
      const path = GLib.build_filenamev([IMAGE_CACHE, info.get_name()]);
      if (!keep.has(path)) GLib.unlink(path);
    }
    children.close(null);
  } catch {
    // The cache is best effort; a failed sweep retries on the next change.
  }
}

// Grouped history, newest group first. Every mutation republishes it.
export const [groups, setGroups] = createState<Group[]>([]);

// Group keys currently shown as transient popups, newest first. A new message
// in a group moves its popup to the top instead of stacking another one.
export const [popupKeys, setPopupKeys] = createState<string[]>([]);

// The group whose accordion the pointer is over in the center, kept here so a
// republished history does not collapse the card under the pointer.
export const [hoveredKey, setHoveredKey] = createState<string | null>(null);

// Notification center dropdown visibility. Raw state only; open/close/toggle are
// coordinated in dashboard-state so the center joins the panel exclusion group.
export const [centerVisible, setCenterVisible] = createState(false);

// Hiding the center takes the pointer away without a leave event, which would
// leave the last hovered accordion open the next time the center shows.
centerVisible.subscribe(() => {
  if (!centerVisible.get()) setHoveredKey(null);
});

const POPUP_FALLBACK_MS = 5000;
const timers = new Map<string, number>();
// Each popup's hide delay, kept so hovering can pause it and leaving restart it.
const popupTimeouts = new Map<string, number>();

function publish(): void {
  const next = history.groups();
  const live = new Set(next.map((g) => g.key));
  setGroups(next);
  sweepImageCache();
  if (popupKeys.get().some((key) => !live.has(key))) {
    setPopupKeys(popupKeys.get().filter((key) => live.has(key)));
  }
  const hovered = hoveredKey.get();
  if (hovered !== null && !live.has(hovered)) setHoveredKey(null);
}

// Closes live notifications nothing in the history points at anymore. Each one
// resolves back through the "resolved" handler, which finds nothing to remove.
function dismissLive(ids: number[]): void {
  for (const id of ids) {
    try {
      notifd.get_notification(id)?.dismiss();
    } catch {
      // already gone
    }
  }
}

function clearTimer(key: string): void {
  const source = timers.get(key);
  if (source) {
    GLib.source_remove(source);
    timers.delete(key);
  }
}

function hidePopup(key: string): void {
  clearTimer(key);
  popupTimeouts.delete(key);
  setPopupKeys(popupKeys.get().filter((x) => x !== key));
}

// Starts (or restarts) the hide timer of a popup. Popups without a stored
// delay are critical ones, which stay until dismissed.
function schedulePopupHide(key: string): void {
  clearTimer(key);
  const timeout = popupTimeouts.get(key);
  if (timeout === undefined) return;
  const source = GLib.timeout_add(GLib.PRIORITY_DEFAULT, timeout, () => {
    timers.delete(key);
    hidePopup(key);
    return GLib.SOURCE_REMOVE;
  });
  timers.set(key, source);
}

export function dismissPopup(key: string): void {
  hidePopup(key);
  // The card goes away under the pointer without a leave event.
  unhoverGroup(key);
}

export function dismissGroup(key: string): void {
  dismissPopup(key);
  const ids = history.removeGroup(key);
  publish();
  dismissLive(ids);
}

export function dismissAll(): void {
  const ids = history.clear();
  publish();
  dismissLive(ids);
}

// Hovering a group unfolds its accordion and, for a popup, holds it on screen
// so the unfolded thread can be read; leaving restarts the popup's full delay.
export function hoverGroup(key: string): void {
  setHoveredKey(key);
  clearTimer(key);
}

export function unhoverGroup(key: string): void {
  if (hoveredKey.get() === key) setHoveredKey(null);
  if (popupKeys.get().includes(key)) schedulePopupHide(key);
}

function urgencyOf(urgency: AstalNotifd.Urgency): Urgency {
  if (urgency === AstalNotifd.Urgency.CRITICAL) return "critical";
  if (urgency === AstalNotifd.Urgency.LOW) return "low";
  return "normal";
}

// Only treat `image` as content (a photo or screenshot) when it is a file path;
// an icon name there is the app logo, which the card already shows small.
function contentImageOf(notification: AstalNotifd.Notification): string {
  const image = notification.image ?? "";
  return image.startsWith("/") || image.startsWith("file://") ? image : "";
}

function snapshot(
  notification: AstalNotifd.Notification,
  arrivedMs: number,
): Incoming {
  return {
    notifId: notification.id,
    appName: notification.appName || "Notification",
    appIcon: keepFile(notification.appIcon || ""),
    summary: notification.summary ?? "",
    body: notification.body ?? "",
    image: keepFile(contentImageOf(notification)),
    urgency: urgencyOf(notification.urgency),
    actions: notification.actions.map((a) => a.id),
    time: notification.time || Math.floor(Date.now() / 1000),
    arrivedMs,
  };
}

function showPopup(key: string, notification: AstalNotifd.Notification): void {
  setPopupKeys([key, ...popupKeys.get().filter((x) => x !== key)]);

  // Critical notifications never auto-hide; others use their own timeout or a
  // fallback. This only hides the popup, not the history entry. A popup under
  // the pointer keeps waiting until the pointer leaves.
  if (notification.urgency === AstalNotifd.Urgency.CRITICAL) {
    clearTimer(key);
    popupTimeouts.delete(key);
    return;
  }
  popupTimeouts.set(
    key,
    notification.expireTimeout > 0 ? notification.expireTimeout : POPUP_FALLBACK_MS,
  );
  if (hoveredKey.get() !== key) schedulePopupHide(key);
}

// Notifications the daemon restored from its state file arrive without a
// "notified" signal, so seed the history with them, oldest first.
for (const notification of [...notifd.get_notifications()].sort(
  (a, b) => (a.time ?? 0) - (b.time ?? 0),
)) {
  history.add(snapshot(notification, (notification.time ?? 0) * 1000));
}
publish();

notifd.connect("notified", (_n, id: number) => {
  const notification = notifd.get_notification(id);
  if (!notification) return;

  const result = history.add(snapshot(notification, Date.now()));
  publish();
  dismissLive(result.orphaned);

  // A repeat of a message already shown gets no second popup, and Do Not
  // Disturb keeps the message in the center without popping it up.
  if (result.duplicate || notifd.dontDisturb) return;
  showPopup(result.message.groupKey, notification);
});

// A notification the user dismissed elsewhere takes its messages with it; one
// its sender closed keeps them (see NotificationHistory.resolveNotification).
notifd.connect("resolved", (_n, id: number, reason: AstalNotifd.ClosedReason) => {
  const closedBySender = reason === AstalNotifd.ClosedReason.CLOSED;
  if (history.resolveNotification(id, { closedBySender })) publish();
});

// Periodic sweep for age-based expiry (count is also enforced on arrival).
GLib.timeout_add_seconds(GLib.PRIORITY_DEFAULT, PRUNE_INTERVAL_SECONDS, () => {
  const before = history.size;
  const orphaned = history.prune(Math.floor(Date.now() / 1000));
  if (history.size !== before) publish();
  dismissLive(orphaned);
  return GLib.SOURCE_CONTINUE;
});
