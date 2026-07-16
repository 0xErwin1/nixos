import GLib from "gi://GLib";
import { With } from "ags";
import { Gtk } from "ags/gtk4";
import { createPoll } from "ags/time";

import { weather, WeatherData } from "./weather";
import { weatherGlyph } from "../glyphs";
import { toggleCalendar } from "./dashboard-state";

// Current temperature + condition glyph shown next to the date for an at-a-glance
// read; the full forecast lives in the calendar panel this island opens.
function MiniWeather() {
  return (
    <With value={weather}>
      {(w: WeatherData | null) =>
        w ? (
          <box cssClasses={["date-weather"]} spacing={7} valign={Gtk.Align.CENTER}>
            <label
              cssClasses={["date-weather-icon"]}
              label={weatherGlyph(w.code, w.isNight)}
              valign={Gtk.Align.CENTER}
            />
            <label
              cssClasses={["date-weather-temp"]}
              label={`${w.temp}°`}
              valign={Gtk.Align.CENTER}
            />
          </box>
        ) : (
          <box visible={false} />
        )
      }
    </With>
  );
}

// Centered date island: time (with seconds) stacked over the full date, with the
// current weather beside it. Clicking the island opens the calendar + weather
// panel. Horizontal: "HH:MM:SS" bold over "Weekday, Mon DD" muted. Vertical: HH
// over MM (the narrow bar has no room for the full stacked date).
export default function Center({ vertical }: { vertical: boolean }) {
  if (vertical) {
    const hh = createPoll(
      "",
      1000,
      () => GLib.DateTime.new_now_local().format("%H")!,
    );
    const mm = createPoll(
      "",
      1000,
      () => GLib.DateTime.new_now_local().format("%M")!,
    );

    return (
      <box
        cssClasses={["island", "date-island", "date-vertical"]}
        orientation={Gtk.Orientation.VERTICAL}
        valign={Gtk.Align.CENTER}
      >
        <label cssClasses={["date-time"]} label={hh} valign={Gtk.Align.CENTER} />
        <label cssClasses={["date-time"]} label={mm} valign={Gtk.Align.CENTER} />
      </box>
    );
  }

  const time = createPoll(
    "",
    1000,
    () => GLib.DateTime.new_now_local().format("%H:%M:%S")!,
  );
  const date = createPoll(
    "",
    1000,
    () => GLib.DateTime.new_now_local().format("%A, %b %d")!,
  );

  return (
    <box
      cssClasses={["island", "date-island", "date-clickable"]}
      spacing={10}
      valign={Gtk.Align.CENTER}
    >
      <Gtk.GestureClick onPressed={() => toggleCalendar()} />
      <box orientation={Gtk.Orientation.VERTICAL} valign={Gtk.Align.CENTER}>
        <label cssClasses={["date-time"]} label={time} valign={Gtk.Align.CENTER} />
        <label cssClasses={["date-date"]} label={date} valign={Gtk.Align.CENTER} />
      </box>
      <MiniWeather />
    </box>
  );
}
