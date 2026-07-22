import GLib from "gi://GLib";
import AstalNotifd from "gi://AstalNotifd";
import { createState } from "ags";

// Instantiating the daemon acquires the org.freedesktop.Notifications bus name
// (only if free — dunst must be gone), making the bar the notification server.
export const notifd = AstalNotifd.get_default();

// Keep notifications in the center until the user dismisses them. By default the
// daemon closes each one when its expire timeout elapses, which also drops it
// from notifd.notifications (the center's source) — so notifications appeared to
// vanish. The transient popup is still hidden on its own timer below; ignoring
// the timeout only affects the stored history.
//
// Unbounded history freezes the bar over long sessions (every notif is a live
// GObject + center For row). Cap count and age so the store cannot grow forever.
notifd.ignoreTimeout = true;

const MAX_STORED = 50;
// Drop anything older than 12h from the center even if the user never cleared.
const MAX_AGE_SECONDS = 12 * 3600;
const PRUNE_INTERVAL_SECONDS = 120;

// Transient popup ids (a subset of notifd.notifications shown as popups until
// they time out / are dismissed). The notification center reads the full
// notifd.notifications list instead, so dismissing a popup keeps it in history.
export const [popupIds, setPopupIds] = createState<number[]>([]);

// Notification center dropdown visibility. Raw state only; open/close/toggle are
// coordinated in dashboard-state so the center joins the panel exclusion group.
export const [centerVisible, setCenterVisible] = createState(false);

const POPUP_FALLBACK_MS = 5000;
const timers = new Map<number, number>();

function clearTimer(id: number): void {
  const source = timers.get(id);
  if (source) {
    GLib.source_remove(source);
    timers.delete(id);
  }
}

function dropPopup(id: number): void {
  setPopupIds(popupIds.get().filter((x) => x !== id));
}

export function dismissPopup(id: number): void {
  clearTimer(id);
  dropPopup(id);
}

function pruneHistory(): void {
  const list = [...notifd.get_notifications()];
  if (list.length === 0) return;

  const now = Math.floor(Date.now() / 1000);

  // Oldest first for count eviction. Astal notifications expose `time` as unix s.
  const sorted = list.slice().sort((a, b) => (a.time ?? 0) - (b.time ?? 0));

  for (const n of sorted) {
    const age = now - (n.time ?? now);
    if (age > MAX_AGE_SECONDS) {
      try {
        n.dismiss();
      } catch {
        // already gone
      }
    }
  }

  const remaining = [...notifd.get_notifications()].sort(
    (a, b) => (a.time ?? 0) - (b.time ?? 0),
  );
  const overflow = remaining.length - MAX_STORED;
  if (overflow > 0) {
    for (let i = 0; i < overflow; i++) {
      try {
        remaining[i].dismiss();
      } catch {
        // already gone
      }
    }
  }
}

notifd.connect("notified", (_n, id: number) => {
  // In Do Not Disturb, suppress the popup but let the daemon keep it in
  // notifd.notifications so it still lands in the center.
  if (notifd.dontDisturb) {
    pruneHistory();
    return;
  }

  const notification = notifd.get_notification(id);
  if (!notification) return;

  setPopupIds([id, ...popupIds.get().filter((x) => x !== id)]);

  // Critical notifications never auto-expire; others use their own timeout or a
  // fallback. This only removes the popup, not the notification itself.
  if (notification.urgency !== AstalNotifd.Urgency.CRITICAL) {
    const timeout =
      notification.expireTimeout > 0
        ? notification.expireTimeout
        : POPUP_FALLBACK_MS;

    clearTimer(id);
    const source = GLib.timeout_add(GLib.PRIORITY_DEFAULT, timeout, () => {
      timers.delete(id);
      dropPopup(id);
      return GLib.SOURCE_REMOVE;
    });
    timers.set(id, source);
  }

  // Keep the store bounded right after each arrival so a burst cannot pile up.
  pruneHistory();
});

// A notification resolved elsewhere (dismissed from the center, expired, or
// closed by its sender) should also drop its popup.
notifd.connect("resolved", (_n, id: number) => {
  clearTimer(id);
  dropPopup(id);
});

// Periodic sweep for age-based expiry (count is also enforced on notify).
GLib.timeout_add_seconds(GLib.PRIORITY_DEFAULT, PRUNE_INTERVAL_SECONDS, () => {
  pruneHistory();
  return GLib.SOURCE_CONTINUE;
});
