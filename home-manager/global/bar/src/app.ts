import app from "ags/gtk4/app";
import style from "./style.scss";
import Bar from "./Bar";
import Dashboard from "./modules/dashboard";
import { NotificationPopups, NotificationCenter } from "./modules/notifications";

app.start({
  css: style,
  // Pin the widget theme so the bar is self-styled and does not depend on the
  // user's GTK theme (their palenight theme ships no GTK4 variant).
  gtkTheme: "Adwaita",
  main() {
    // Separate OVERLAY windows (hidden until opened / until a notification
    // arrives); instantiating them registers them with the application.
    Dashboard();
    NotificationPopups();
    NotificationCenter();
    return Bar();
  },
});
