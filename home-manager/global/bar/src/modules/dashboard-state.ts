import { createState } from "ags";

import { centerVisible, setCenterVisible } from "./notify-state";

export type DashboardTab = "wifi" | "bluetooth";

// Global visibility + active-tab state for the connectivity dashboard. The bar
// trigger icons import openDashboard() to open it on a specific tab; the
// dashboard window binds dashboardVisible and closes via closeDashboard().
export const [dashboardVisible, setDashboardVisible] = createState(false);
export const [activeTab, setActiveTab] = createState<DashboardTab>("wifi");

// Calendar panel visibility (opened from the center date island) and media
// panel visibility (opened from the media island). Kept here so all panels can
// be mutually exclusive without a circular import: opening one closes the rest.
export const [calendarVisible, setCalendarVisible] = createState(false);
export const [mediaVisible, setMediaVisible] = createState(false);
export const [extrasVisible, setExtrasVisible] = createState(false);

type Panel = "dashboard" | "calendar" | "media" | "extras" | "center";

function closeOthers(keep: Panel): void {
  if (keep !== "dashboard") setDashboardVisible(false);
  if (keep !== "calendar") setCalendarVisible(false);
  if (keep !== "media") setMediaVisible(false);
  if (keep !== "extras") setExtrasVisible(false);
  if (keep !== "center") setCenterVisible(false);
}

// True when any dropdown panel is currently open. The bar triggers use this to
// implement hover-switching: while a panel is open, hovering another trigger
// switches to it; hovering when nothing is open does nothing.
export function anyPanelOpen(): boolean {
  return (
    dashboardVisible.get() ||
    calendarVisible.get() ||
    mediaVisible.get() ||
    extrasVisible.get() ||
    centerVisible.get()
  );
}

export function openDashboard(tab: DashboardTab): void {
  setActiveTab(tab);
  closeOthers("dashboard");
  setDashboardVisible(true);
}

export function closeDashboard(): void {
  setDashboardVisible(false);
}

export function toggleCalendar(): void {
  const next = !calendarVisible.get();
  if (next) closeOthers("calendar");
  setCalendarVisible(next);
}

export function closeCalendar(): void {
  setCalendarVisible(false);
}

export function toggleMedia(): void {
  const next = !mediaVisible.get();
  if (next) closeOthers("media");
  setMediaVisible(next);
}

export function closeMedia(): void {
  setMediaVisible(false);
}

export function toggleExtras(): void {
  const next = !extrasVisible.get();
  if (next) closeOthers("extras");
  setExtrasVisible(next);
}

export function closeExtras(): void {
  setExtrasVisible(false);
}

// The notification center (bell / brightness / volume / mic triggers) joins the
// same mutually-exclusive group as the other panels. Its visibility state still
// lives in notify-state (next to the daemon), but opening is coordinated here so
// it closes every other panel — and they close it.
export function openCenter(): void {
  closeOthers("center");
  setCenterVisible(true);
}

export function closeCenter(): void {
  setCenterVisible(false);
}

export function toggleCenter(): void {
  const next = !centerVisible.get();
  if (next) closeOthers("center");
  setCenterVisible(next);
}
