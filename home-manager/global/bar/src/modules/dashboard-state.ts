import { createState } from "ags";

export type DashboardTab = "wifi" | "bluetooth";

// Global visibility + active-tab state for the connectivity dashboard. The bar
// trigger icons import openDashboard() to open it on a specific tab; the
// dashboard window binds dashboardVisible and closes via closeDashboard().
export const [dashboardVisible, setDashboardVisible] = createState(false);
export const [activeTab, setActiveTab] = createState<DashboardTab>("wifi");

export function openDashboard(tab: DashboardTab): void {
  setActiveTab(tab);
  setDashboardVisible(true);
}

export function closeDashboard(): void {
  setDashboardVisible(false);
}
