import app from "ags/gtk4/app";
import style from "./style.scss";
import Bar from "./Bar";
import Dashboard from "./modules/dashboard";

app.start({
  css: style,
  // Pin the widget theme so the bar is self-styled and does not depend on the
  // user's GTK theme (their palenight theme ships no GTK4 variant).
  gtkTheme: "Adwaita",
  main() {
    // The dashboard is a separate OVERLAY window (hidden until a bar trigger
    // opens it); instantiating it registers it with the application.
    Dashboard();
    return Bar();
  },
});
