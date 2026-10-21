import app from "ags/gtk4/app";
import Bar from "./Bar";
import Dashboard from "./modules/dashboard";
import Calendar from "./modules/calendar";
import { MediaPanel } from "./modules/media";
import { ExtrasPanel } from "./modules/extras";
import { AppearancePanel } from "./modules/appearance";
import { cssFor, theme } from "./modules/theme-state";
import { NotificationPopups, NotificationCenter } from "./modules/notifications";

app.start({
  // Every theme's CSS is bundled; start on the persisted one. theme-state
  // swaps it at runtime with apply_css(css, true).
  css: cssFor(theme.get()),
  // Pin the widget theme so the bar is self-styled and does not follow the
  // GTK theme wl-theme switches in dconf. Nothing may set GTK_THEME, which
  // would override this.
  gtkTheme: "Adwaita",
  main() {
    // Separate OVERLAY windows (hidden until opened / until a notification
    // arrives); instantiating them registers them with the application.
    Dashboard();
    Calendar();
    MediaPanel();
    ExtrasPanel();
    AppearancePanel();
    NotificationPopups();
    NotificationCenter();
    return Bar();
  },
});
