import GLib from "gi://GLib";
import { Gtk } from "ags/gtk4";

// Bar edge is chosen at startup via the BAR_EDGE env var so the position can be
// tried without rebuilding. "top"/"bottom" produce a horizontal bar spanning
// ~95% of the monitor width; "left"/"right" produce a narrow vertical bar
// spanning ~95% of the height. Anything else falls back to the default "bottom".
export const EDGE = (GLib.getenv("BAR_EDGE") || "bottom").toLowerCase();
export const VERTICAL = EDGE === "left" || EDGE === "right";

/**
 * Vertical alignment for popover cards: they hug the bar's edge, so a bottom
 * bar opens its panels upward. Every other edge keeps them at the top.
 */
export const CARD_VALIGN = EDGE === "bottom" ? Gtk.Align.END : Gtk.Align.START;
