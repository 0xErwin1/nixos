import { createState } from "ags";

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

type Panel = "dashboard" | "calendar" | "media" | "extras";

function closeOthers(keep: Panel): void {
  if (keep !== "dashboard") setDashboardVisible(false);
  if (keep !== "calendar") setCalendarVisible(false);
  if (keep !== "media") setMediaVisible(false);
  if (keep !== "extras") setExtrasVisible(false);
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
