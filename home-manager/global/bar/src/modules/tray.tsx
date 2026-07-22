import AstalTray from "gi://AstalTray";
import { For, createBinding, onCleanup } from "ags";
import { Gtk } from "ags/gtk4";

const tray = AstalTray.get_default();

function initItem(button: Gtk.MenuButton, item: AstalTray.TrayItem) {
  // DBusMenu hosts (Slack, Nextcloud, …) rebuild their GtkStack often and spam
  // "duplicate child name" on the main loop when we re-insert the action group
  // on every notify. Only push when the GObject identity actually changes.
  let lastModel: unknown = null;
  let lastGroup: unknown = null;

  const sync = () => {
    const model = item.menuModel;
    const group = item.actionGroup;

    if (model && model !== lastModel) {
      button.menuModel = model;
      lastModel = model;
    }

    if (group && group !== lastGroup) {
      button.insert_action_group("dbusmenu", group);
      lastGroup = group;
    }
  };

  sync();

  const modelId = item.connect("notify::menu-model", sync);
  const groupId = item.connect("notify::action-group", sync);

  onCleanup(() => {
    try {
      item.disconnect(modelId);
      item.disconnect(groupId);
    } catch {
      // Item may already be gone when the For row is torn down.
    }
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
