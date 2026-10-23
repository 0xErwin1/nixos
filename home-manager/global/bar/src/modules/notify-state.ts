import GLib from "gi://GLib";
import AstalNotifd from "gi://AstalNotifd";
import { createState } from "ags";

import {
  NotificationHistory,
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

function publish(): void {
  const next = history.groups();
  const live = new Set(next.map((g) => g.key));
  setGroups(next);
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

export function dismissPopup(key: string): void {
  clearTimer(key);
  setPopupKeys(popupKeys.get().filter((x) => x !== key));
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

export function hoverGroup(key: string): void {
  setHoveredKey(key);
}

export function unhoverGroup(key: string): void {
  if (hoveredKey.get() === key) setHoveredKey(null);
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
    appIcon: notification.appIcon || "",
    summary: notification.summary ?? "",
    body: notification.body ?? "",
    image: contentImageOf(notification),
    urgency: urgencyOf(notification.urgency),
    actions: notification.actions.map((a) => a.id),
    time: notification.time || Math.floor(Date.now() / 1000),
    arrivedMs,
  };
}

function showPopup(key: string, notification: AstalNotifd.Notification): void {
  setPopupKeys([key, ...popupKeys.get().filter((x) => x !== key)]);

  // Critical notifications never auto-hide; others use their own timeout or a
  // fallback. This only hides the popup, not the history entry.
  clearTimer(key);
  if (notification.urgency === AstalNotifd.Urgency.CRITICAL) return;
  const timeout =
    notification.expireTimeout > 0 ? notification.expireTimeout : POPUP_FALLBACK_MS;
  const source = GLib.timeout_add(GLib.PRIORITY_DEFAULT, timeout, () => {
    timers.delete(key);
    setPopupKeys(popupKeys.get().filter((x) => x !== key));
    return GLib.SOURCE_REMOVE;
  });
  timers.set(key, source);
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

// A notification resolved elsewhere (dismissed, or closed by its sender, as
// WhatsApp does once the chat is read) takes its messages with it.
notifd.connect("resolved", (_n, id: number) => {
  if (history.removeNotification(id)) publish();
});

// Periodic sweep for age-based expiry (count is also enforced on arrival).
GLib.timeout_add_seconds(GLib.PRIORITY_DEFAULT, PRUNE_INTERVAL_SECONDS, () => {
  const before = history.size;
  const orphaned = history.prune(Math.floor(Date.now() / 1000));
  if (history.size !== before) publish();
  dismissLive(orphaned);
  return GLib.SOURCE_CONTINUE;
});
