import app from "ags/gtk4/app";
import { Astal, Gdk, Gtk } from "ags/gtk4";

import { CARD_VALIGN } from "./edge";
import { CLOSE_GLYPH, MODE_DARK, MODE_LIGHT, PALETTE } from "../glyphs";
import { FAMILIES } from "../themes/index";
import {
  appearanceVisible,
  anyPanelOpen,
  closeAppearance,
  openAppearance,
  toggleAppearance,
} from "./dashboard-state";
import {
  family,
  mode,
  setFamily,
  setMode,
  type ThemeFamily,
  type ThemeMode,
} from "./theme-state";

const FAMILY_ORDER: ThemeFamily[] = ["ayu", "byzantium"];

// Bar island that opens the Appearance panel, following the other triggers:
// click toggles, hovering switches to it while another panel is open.
export function AppearanceTrigger() {
  return (
    <box cssClasses={["island", "appearance"]} valign={Gtk.Align.CENTER}>
      <box
        cssClasses={["control-item", "appearance-trigger", "dash-trigger"]}
        valign={Gtk.Align.CENTER}
      >
        <Gtk.GestureClick onPressed={() => toggleAppearance()} />
        <Gtk.EventControllerMotion
          onEnter={() => {
            if (anyPanelOpen()) openAppearance();
          }}
        />
        <label
          cssClasses={["control-icon"]}
          label={PALETTE}
          valign={Gtk.Align.CENTER}
        />
      </box>
    </box>
  );
}

/**
 * Miniature desktop drawn in a family's colors for the current mode. The
 * `pv-<id>` color classes are generated for every theme into every bundle, so
 * the preview never depends on the active theme.
 */
function Preview({ themeFamily }: { themeFamily: ThemeFamily }) {
  return (
    <box
      cssClasses={mode((m) => ["theme-preview", `pv-${themeFamily}-${m}`])}
      orientation={Gtk.Orientation.VERTICAL}
      spacing={8}
    >
      <box cssClasses={["pv-strip"]} spacing={4}>
        <box cssClasses={["pv-dot"]} valign={Gtk.Align.CENTER} />
        <box cssClasses={["pv-dot"]} valign={Gtk.Align.CENTER} />
        <box cssClasses={["pv-dot"]} valign={Gtk.Align.CENTER} />
        <box hexpand />
        <box cssClasses={["pv-pill"]} valign={Gtk.Align.CENTER} />
      </box>

      <box cssClasses={["pv-window"]} orientation={Gtk.Orientation.VERTICAL} spacing={6}>
        <box cssClasses={["pv-title"]} halign={Gtk.Align.START} />
        <box cssClasses={["pv-line", "pv-line-long"]} halign={Gtk.Align.START} />
        <box cssClasses={["pv-line", "pv-line-short"]} halign={Gtk.Align.START} />

        <box spacing={4}>
          <box cssClasses={["pv-swatch", "pv-swatch-0"]} valign={Gtk.Align.CENTER} />
          <box cssClasses={["pv-swatch", "pv-swatch-1"]} valign={Gtk.Align.CENTER} />
          <box cssClasses={["pv-swatch", "pv-swatch-2"]} valign={Gtk.Align.CENTER} />
          <box cssClasses={["pv-swatch", "pv-swatch-3"]} valign={Gtk.Align.CENTER} />
          <box hexpand />
          <box cssClasses={["pv-button"]} valign={Gtk.Align.CENTER} />
        </box>
      </box>
    </box>
  );
}

function FamilyCard({ themeFamily }: { themeFamily: ThemeFamily }) {
  const info = FAMILIES[themeFamily];

  return (
    <button
      cssClasses={family((f) =>
        f === themeFamily ? ["theme-card", "selected"] : ["theme-card"],
      )}
      onClicked={() => setFamily(themeFamily)}
    >
      <box orientation={Gtk.Orientation.VERTICAL} spacing={8}>
        <Preview themeFamily={themeFamily} />
        <label cssClasses={["theme-name"]} label={info.name} halign={Gtk.Align.START} />
        <label
          cssClasses={["theme-desc"]}
          label={info.description}
          halign={Gtk.Align.START}
        />
      </box>
    </button>
  );
}

function ModeButton({ value, glyph, text }: { value: ThemeMode; glyph: string; text: string }) {
  return (
    <button
      cssClasses={mode((m) => (m === value ? ["mode-btn", "active"] : ["mode-btn"]))}
      onClicked={() => setMode(value)}
    >
      <box spacing={6} halign={Gtk.Align.CENTER}>
        <label cssClasses={["mode-glyph"]} label={glyph} />
        <label label={text} />
      </box>
    </button>
  );
}

// Appearance panel: a full-screen layer window with a transparent backdrop and
// a card at the bar edge, like the other panels. Closes on Esc, a backdrop
// click or losing focus.
export function AppearancePanel() {
  const { TOP, BOTTOM, LEFT, RIGHT } = Astal.WindowAnchor;

  return (
    <window
      name="appearance-panel"
      namespace="wl-appearance"
      visible={appearanceVisible}
      cssClasses={["appearance-window"]}
      anchor={TOP | BOTTOM | LEFT | RIGHT}
      exclusivity={Astal.Exclusivity.NORMAL}
      layer={Astal.Layer.TOP}
      keymode={Astal.Keymode.ON_DEMAND}
      onNotifyIsActive={(self) => {
        if (!self.isActive) closeAppearance();
      }}
      application={app}
    >
      <Gtk.EventControllerKey
        onKeyPressed={(_c, keyval: number) => {
          if (keyval === Gdk.KEY_Escape) closeAppearance();
        }}
      />
      <overlay>
        <button cssClasses={["appearance-backdrop"]} onClicked={closeAppearance} />
        <box
          $type="overlay"
          cssClasses={["panel-card"]}
          orientation={Gtk.Orientation.VERTICAL}
          halign={Gtk.Align.END}
          valign={CARD_VALIGN}
          marginTop={8}
          marginBottom={8}
          marginEnd={8}
          spacing={14}
        >
          <box cssClasses={["panel-header"]}>
            <label cssClasses={["panel-title"]} label="Appearance" hexpand xalign={0} />
            <button cssClasses={["panel-close"]} onClicked={closeAppearance}>
              <label label={CLOSE_GLYPH} />
            </button>
          </box>

          <box spacing={12} homogeneous>
            {FAMILY_ORDER.map((f) => (
              <FamilyCard themeFamily={f} />
            ))}
          </box>

          <box orientation={Gtk.Orientation.VERTICAL} spacing={6}>
            <box cssClasses={["panel-section-head"]}>
              <label cssClasses={["panel-section-label"]} label="MODE" hexpand xalign={0} />
            </box>

            <box cssClasses={["panel-group", "mode-seg"]} homogeneous>
              <ModeButton value="light" glyph={MODE_LIGHT} text="Light" />
              <ModeButton value="dark" glyph={MODE_DARK} text="Dark" />
            </box>
          </box>
        </box>
      </overlay>
    </window>
  );
}
