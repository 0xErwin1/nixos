import { Gtk } from "ags/gtk4";

// LONG_AXIS_FRACTION from Bar.tsx: the bar window's own left margin, which sits
// between the monitor edge and an island's root-relative x.
const BAR_LEFT_FRACTION = 0.0125;

// Measure an island's x on the monitor so a full-screen dropdown panel can align
// its card under it (layer-shell windows can't anchor to a widget). Best-effort:
// any failure falls back to a small left margin.
export function measureIslandX(island: Gtk.Widget): number {
  try {
    const root = island.get_root() as Gtk.Widget | null;
    if (!root) return 8;

    const [ok, rect] = island.compute_bounds(root);
    if (!ok) return 8;

    let barLeftMargin = 0;
    const surface = island.get_native()?.get_surface?.();
    const display = island.get_display();
    if (surface && display) {
      const monitor = display.get_monitor_at_surface(surface);
      if (monitor) {
        barLeftMargin = Math.round(monitor.get_geometry().width * BAR_LEFT_FRACTION);
      }
    }

    return Math.round(rect.get_x()) + barLeftMargin;
  } catch {
    return 8;
  }
}
