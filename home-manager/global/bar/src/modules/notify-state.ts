import GLib from "gi://GLib";
import AstalNotifd from "gi://AstalNotifd";
import { createState } from "ags";

// Instantiating the daemon acquires the org.freedesktop.Notifications bus name
// (only if free — dunst must be gone), making the bar the notification server.
export const notifd = AstalNotifd.get_default();

// Transient popup ids (a subset of notifd.notifications shown as popups until
// they time out / are dismissed). The notification center reads the full
// notifd.notifications list instead, so dismissing a popup keeps it in history.
export const [popupIds, setPopupIds] = createState<number[]>([]);

// Notification center dropdown visibility.
export const [centerVisible, setCenterVisible] = createState(false);

export function openCenter(): void {
  setCenterVisible(true);
}

export function closeCenter(): void {
  setCenterVisible(false);
}

export function toggleCenter(): void {
  setCenterVisible(!centerVisible.get());
}

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

notifd.connect("notified", (_n, id: number) => {
  // In Do Not Disturb, suppress the popup but let the daemon keep it in
  // notifd.notifications so it still lands in the center.
  if (notifd.dontDisturb) return;

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

    const source = GLib.timeout_add(GLib.PRIORITY_DEFAULT, timeout, () => {
      timers.delete(id);
      dropPopup(id);
      return GLib.SOURCE_REMOVE;
    });
    timers.set(id, source);
  }
});

// A notification resolved elsewhere (dismissed from the center, expired, or
// closed by its sender) should also drop its popup.
notifd.connect("resolved", (_n, id: number) => {
  clearTimer(id);
  dropPopup(id);
});
