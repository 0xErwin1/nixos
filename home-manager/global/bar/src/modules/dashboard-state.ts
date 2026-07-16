import { createState } from "ags";

export type DashboardTab = "wifi" | "bluetooth";

// Global visibility + active-tab state for the connectivity dashboard. The bar
// trigger icons import openDashboard() to open it on a specific tab; the
// dashboard window binds dashboardVisible and closes via closeDashboard().
export const [dashboardVisible, setDashboardVisible] = createState(false);
export const [activeTab, setActiveTab] = createState<DashboardTab>("wifi");

// Calendar panel visibility (opened from the center date island). Kept here so
// the two panels can be mutually exclusive without a circular import: opening
// one closes the other.
export const [calendarVisible, setCalendarVisible] = createState(false);

export function openDashboard(tab: DashboardTab): void {
  setActiveTab(tab);
  setCalendarVisible(false);
  setDashboardVisible(true);
}

export function closeDashboard(): void {
  setDashboardVisible(false);
}

export function toggleCalendar(): void {
  const next = !calendarVisible.get();
  if (next) setDashboardVisible(false);
  setCalendarVisible(next);
}

export function closeCalendar(): void {
  setCalendarVisible(false);
}
