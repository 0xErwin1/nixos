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

export default function Center({ vertical }: { vertical: boolean }) {
  const items = createBinding(tray, "items");

  return (
    <box
      cssClasses={["island", "tray"]}
      visible={items((list) => list.length > 0)}
      orientation={vertical ? Gtk.Orientation.VERTICAL : Gtk.Orientation.HORIZONTAL}
      spacing={vertical ? 4 : 5}
      halign={Gtk.Align.CENTER}
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
