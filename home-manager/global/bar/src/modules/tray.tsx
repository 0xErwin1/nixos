import AstalTray from "gi://AstalTray";
import { For, createBinding } from "ags";
import { Gtk } from "ags/gtk4";

const tray = AstalTray.get_default();

function initItem(button: Gtk.MenuButton, item: AstalTray.TrayItem) {
  button.menuModel = item.menuModel;
  button.insert_action_group("dbusmenu", item.actionGroup);
  item.connect("notify::action-group", () => {
    button.insert_action_group("dbusmenu", item.actionGroup);
  });
}

// System tray island (rightmost in the end group). Hidden when there are no
// tray items so it doesn't show an empty pill.
export default function Tray({ vertical }: { vertical: boolean }) {
  const items = createBinding(tray, "items");

  return (
    <box
      cssClasses={["island", "tray"]}
      visible={items((list) => list.length > 0)}
      orientation={vertical ? Gtk.Orientation.VERTICAL : Gtk.Orientation.HORIZONTAL}
      spacing={vertical ? 4 : 5}
      valign={Gtk.Align.CENTER}
    >
      <For each={items}>
        {(item) => (
          <menubutton
            cssClasses={["tray-item"]}
            valign={Gtk.Align.CENTER}
            $={(self) => initItem(self, item)}
          >
            <image gicon={createBinding(item, "gicon")} />
          </menubutton>
        )}
      </For>
    </box>
  );
}
