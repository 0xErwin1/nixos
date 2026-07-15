import { Gtk } from "ags/gtk4";

export function Separator() {
  return (
    <label cssClasses={["separator"]} label="│" valign={Gtk.Align.CENTER} />
  );
}
