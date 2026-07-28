import AstalTray from "gi://AstalTray";
import GLib from "gi://GLib";
import Gio from "gi://Gio";
import { For, createBinding, onCleanup } from "ags";
import { Gtk } from "ags/gtk4";

const tray = AstalTray.get_default();

function initItem(button: Gtk.MenuButton, item: AstalTray.TrayItem) {
  // Never leave the item's menu model attached while the popover is closed.
  // Once a model is set, GtkMenuButton's popover menu tracker stays subscribed
  // to the model's items-changed, and DBusMenu hosts (udiskie, solaar, Slack,
  // …) rebuild their menus in storms — enough churn livelocks the GTK main
  // loop inside gtk_menu_tracker/gtk_action_muxer (100% CPU, frozen bar).
  // While the menu is shut the button holds a static empty placeholder model
  // instead of null: GtkMenuButton makes itself insensitive without a model,
  // which would dim the icon and swallow the first click. The real model is
  // swapped in on press, right before the popover opens, and swapped back out
  // as soon as it closes so churn never reaches GTK while the menu is shut.
  const placeholder = new Gio.Menu();
  button.menuModel = placeholder;

  let lastGroup: unknown = null;
  let detachSource = 0;

  const cancelDetach = () => {
    if (detachSource !== 0) {
      GLib.source_remove(detachSource);
      detachSource = 0;
    }
  };

  const attach = () => {
    cancelDetach();

    const group = item.actionGroup;
    if (group && group !== lastGroup) {
      button.insert_action_group("dbusmenu", group);
      lastGroup = group;
    }

    const model = item.menuModel;
    if (model && button.menuModel !== model) {
      button.menuModel = model;
    }
  };

  // Swapping the model back synchronously from notify::active destroys the
  // GtkPopoverMenu — and with it the GtkMenuTrackerItem of the entry that was
  // just chosen — while GTK is still inside the click that closed the popover.
  // GTK hides the popover before it calls gtk_menu_tracker_item_activated, so a
  // synchronous detach drops the activation entirely: the menu closes and the
  // action never fires. Defer to an idle so the current emission finishes
  // first, and re-check `active` so re-opening the menu cancels the detach
  // instead of stealing the model out from under the popover that just opened.
  const scheduleDetach = () => {
    cancelDetach();
    detachSource = GLib.idle_add(GLib.PRIORITY_DEFAULT_IDLE, () => {
      detachSource = 0;
      if (!button.active) {
        button.menuModel = placeholder;
      }
      return GLib.SOURCE_REMOVE;
    });
  };

  // Capture phase so the model exists before the button's own press handler
  // tries to open the (model-derived) popover.
  const press = new Gtk.GestureClick();
  press.set_propagation_phase(Gtk.PropagationPhase.CAPTURE);
  press.connect("pressed", attach);
  button.add_controller(press);

  // DBusMenu hosts are allowed to publish their layout lazily, so the model can
  // still be empty at press time and only arrive after the first AboutToShow.
  // Adopt it then — but only while the popover is open, otherwise this is
  // exactly the while-closed churn the placeholder exists to keep out of GTK.
  const modelId = item.connect("notify::menu-model", () => {
    if (button.active) {
      attach();
    }
  });

  const activeId = button.connect("notify::active", () => {
    if (button.active) {
      cancelDetach();
    } else {
      scheduleDetach();
    }
  });

  onCleanup(() => {
    cancelDetach();

    // A tray item disappears when its app quits (Slack/Teams "Quit"). Electron
    // apps keep owning their D-Bus name for a moment after they stop servicing
    // it, so any synchronous dbusmenu call the popover/importer makes against
    // that now-mute name blocks the GTK main loop until the 25s D-Bus timeout —
    // freezing the whole bar. Detach the button from the dying importer BEFORE
    // disconnecting so GTK never re-queries the dead menu during disposal.
    try {
      button.get_popover()?.popdown();
    } catch {
      // No popover was ever realized.
    }

    try {
      button.menuModel = null;
      button.insert_action_group("dbusmenu", null);
    } catch {
      // Button already being finalized.
    }

    try {
      item.disconnect(modelId);
    } catch {
      // Item may already be gone when the For row is torn down.
    }

    try {
      button.disconnect(activeId);
    } catch {
      // Button already being finalized.
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
