import GLib from "gi://GLib";
import app from "ags/gtk4/app";
import { Astal, Gdk, Gtk } from "ags/gtk4";
import { For, With, createComputed, createState } from "ags";
import { execAsync } from "ags/process";

import {
  calendarVisible,
  closeCalendar,
} from "./dashboard-state";
import {
  weather,
  weatherStatus,
  currentLocation,
  searchLocations,
  setLocation,
  LocationResult,
  LocationSetting,
  WeatherData,
  WeatherDay,
} from "./weather";
import {
  weatherGlyph,
  WIND_GLYPH,
  HUMIDITY_GLYPH,
  RAIN_GLYPH,
  FEELS_GLYPH,
  CHEVRON_LEFT,
  CHEVRON_RIGHT,
  CLOSE_GLYPH,
} from "../glyphs";

const MONTH_NAMES = [
  "January", "February", "March", "April", "May", "June",
  "July", "August", "September", "October", "November", "December",
];
const WEEKDAYS = ["Mo", "Tu", "We", "Th", "Fr", "Sa", "Su"];

const SEARCH_DEBOUNCE_MS = 300;

interface CalEvent {
  time: string;
  title: string;
  calendar: string;
}

interface DayCell {
  day: number;
  dateStr: string;
  inMonth: boolean;
  isToday: boolean;
  hasEvents: boolean;
}

function pad(n: number): string {
  return String(n).padStart(2, "0");
}

function dateKey(year: number, month0: number, day: number): string {
  return `${year}-${pad(month0 + 1)}-${pad(day)}`;
}

function todayKey(): string {
  const t = new Date();
  return dateKey(t.getFullYear(), t.getMonth(), t.getDate());
}

// khal prints only the days that actually have events: a bare "YYYY-MM-DD"
// header line (from --day-format) followed by one "start|end|title|calendar"
// line per event (from --format). Anything else (khal missing, no calendars) is
// swallowed into an empty map so the grid still renders.
function parseKhal(out: string): Record<string, CalEvent[]> {
  const byDay: Record<string, CalEvent[]> = {};
  let current = "";

  for (const raw of out.split("\n")) {
    const line = raw.trim();
    if (!line) continue;

    if (/^\d{4}-\d{2}-\d{2}$/.test(line)) {
      current = line;
      byDay[current] = [];
      continue;
    }

    if (!current) continue;

    const [start, , title, calendar] = line.split("|");
    byDay[current].push({
      time: start.trim(),
      title: (title ?? "").trim(),
      calendar: (calendar ?? "").trim(),
    });
  }

  return byDay;
}

export default function Calendar() {
  const now = new Date();
  const [viewYear, setViewYear] = createState(now.getFullYear());
  const [viewMonth, setViewMonth] = createState(now.getMonth());
  const [selected, setSelected] = createState(todayKey());
  const [events, setEvents] = createState<Record<string, CalEvent[]>>({});

  function loadMonth(): void {
    const year = viewYear.get();
    const month0 = viewMonth.get();
    const start = dateKey(year, month0, 1);
    const days = new Date(year, month0 + 1, 0).getDate();

    execAsync([
      "khal",
      "list",
      "--day-format",
      "{date}",
      "--format",
      " {start-time}|{end-time}|{title}|{calendar}",
      start,
      `${days}d`,
    ])
      .then((out) => setEvents(parseKhal(out)))
      .catch(() => setEvents({}));
  }

  function shiftMonth(delta: number): void {
    let month0 = viewMonth.get() + delta;
    let year = viewYear.get();
    if (month0 < 0) {
      month0 = 11;
      year -= 1;
    } else if (month0 > 11) {
      month0 = 0;
      year += 1;
    }
    setViewYear(year);
    setViewMonth(month0);
    loadMonth();
  }

  // Reload the month's events every time the panel is opened so newly-synced
  // events show up without restarting the bar.
  calendarVisible.subscribe(() => {
    if (calendarVisible.get()) loadMonth();
  });

  const title = createComputed(
    [viewYear, viewMonth],
    (y, m) => `${MONTH_NAMES[m]} ${y}`.toUpperCase(),
  );

  // Six weeks (42 cells) covering the whole month plus leading/trailing days
  // from the adjacent months, so the grid height never jumps between months.
  const weeks = createComputed(
    [viewYear, viewMonth, selected, events],
    (year, month0, sel, evs): DayCell[][] => {
      const first = new Date(year, month0, 1);
      const leading = (first.getDay() + 6) % 7; // Monday-first offset
      const today = todayKey();

      const cells: DayCell[] = [];
      for (let i = 0; i < 42; i++) {
        const date = new Date(year, month0, 1 - leading + i);
        const key = dateKey(date.getFullYear(), date.getMonth(), date.getDate());
        cells.push({
          day: date.getDate(),
          dateStr: key,
          inMonth: date.getMonth() === month0,
          isToday: key === today,
          hasEvents: (evs[key]?.length ?? 0) > 0,
        });
      }

      const rows: DayCell[][] = [];
      for (let r = 0; r < 6; r++) rows.push(cells.slice(r * 7, r * 7 + 7));
      return rows;
    },
  );

  const dayList = createComputed([selected, events], (sel, evs) => evs[sel] ?? []);
  const selectedLabel = selected((s) => s);

  const { TOP, BOTTOM, LEFT, RIGHT } = Astal.WindowAnchor;

  return (
    <window
      name="calendar-panel"
      namespace="wl-calendar"
      visible={calendarVisible}
      cssClasses={["calendar-window"]}
      anchor={TOP | BOTTOM | LEFT | RIGHT}
      exclusivity={Astal.Exclusivity.NORMAL}
      layer={Astal.Layer.TOP}
      keymode={Astal.Keymode.ON_DEMAND}
      onNotifyIsActive={(self) => {
        if (!self.isActive) closeCalendar();
      }}
      application={app}
    >
      <Gtk.EventControllerKey
        onKeyPressed={(_c, keyval: number) => {
          if (keyval === Gdk.KEY_Escape) closeCalendar();
        }}
      />
      <overlay>
        <button cssClasses={["calendar-backdrop"]} onClicked={closeCalendar} />
        <box
          $type="overlay"
          cssClasses={["calendar-card"]}
          halign={Gtk.Align.CENTER}
          valign={Gtk.Align.START}
          spacing={18}
        >
          <box cssClasses={["cal-section"]} orientation={Gtk.Orientation.VERTICAL} spacing={8}>
            <box cssClasses={["cal-header"]} valign={Gtk.Align.CENTER}>
              <button cssClasses={["cal-nav"]} onClicked={() => shiftMonth(-1)}>
                <label label={CHEVRON_LEFT} />
              </button>
              <label cssClasses={["cal-title"]} label={title} hexpand />
              <button cssClasses={["cal-nav"]} onClicked={() => shiftMonth(1)}>
                <label label={CHEVRON_RIGHT} />
              </button>
            </box>

            <box cssClasses={["cal-weekdays"]} homogeneous>
              {WEEKDAYS.map((wd) => (
                <label cssClasses={["cal-weekday"]} label={wd} />
              ))}
            </box>

            <box cssClasses={["cal-grid"]} orientation={Gtk.Orientation.VERTICAL} spacing={2}>
              <For each={weeks}>
                {(week: DayCell[]) => (
                  <box homogeneous spacing={2}>
                    {week.map((cell) => (
                      <button
                        cssClasses={[
                          "cal-day",
                          cell.inMonth ? "" : "cal-day-out",
                          cell.isToday ? "cal-day-today" : "",
                          cell.dateStr === selected.get() ? "cal-day-selected" : "",
                        ]}
                        onClicked={() => setSelected(cell.dateStr)}
                      >
                        <box orientation={Gtk.Orientation.VERTICAL} valign={Gtk.Align.CENTER}>
                          <label label={String(cell.day)} />
                          <box
                            cssClasses={["cal-day-dot"]}
                            visible={cell.hasEvents}
                            halign={Gtk.Align.CENTER}
                          />
                        </box>
                      </button>
                    ))}
                  </box>
                )}
              </For>
            </box>

            <box cssClasses={["cc-box", "cal-events"]} orientation={Gtk.Orientation.VERTICAL} spacing={6}>
              <label cssClasses={["cal-events-title"]} label={selectedLabel} halign={Gtk.Align.START} />
              <box orientation={Gtk.Orientation.VERTICAL} spacing={4}>
                <For each={dayList}>
                  {(ev: CalEvent) => (
                    <box cssClasses={["cal-event"]} spacing={8} valign={Gtk.Align.CENTER}>
                      <label cssClasses={["cal-event-time"]} label={ev.time || "all-day"} />
                      <label cssClasses={["cal-event-title"]} label={ev.title} hexpand halign={Gtk.Align.START} />
                    </box>
                  )}
                </For>
                <label
                  cssClasses={["cal-events-empty"]}
                  label="No events"
                  visible={dayList((l) => l.length === 0)}
                  halign={Gtk.Align.START}
                />
              </box>
            </box>
          </box>

          <box cssClasses={["cal-divider"]} />

          <WeatherSection />
        </box>
      </overlay>
    </window>
  );
}

function Metric({ glyph, value, label }: { glyph: string; value: string; label: string }) {
  return (
    <box
      cssClasses={["wx-metric"]}
      orientation={Gtk.Orientation.VERTICAL}
      spacing={2}
      halign={Gtk.Align.CENTER}
      valign={Gtk.Align.CENTER}
    >
      <label cssClasses={["wx-metric-glyph"]} label={glyph} halign={Gtk.Align.CENTER} />
      <label cssClasses={["wx-metric-value"]} label={value} halign={Gtk.Align.CENTER} />
      <label cssClasses={["wx-metric-label"]} label={label} halign={Gtk.Align.CENTER} />
    </box>
  );
}

function WeatherBody({ w }: { w: WeatherData }) {
  return (
    <box cssClasses={["wx-body"]} orientation={Gtk.Orientation.VERTICAL} spacing={14} valign={Gtk.Align.CENTER}>
      <label cssClasses={["wx-location"]} label={w.location} halign={Gtk.Align.CENTER} />

      <box orientation={Gtk.Orientation.VERTICAL} halign={Gtk.Align.CENTER} spacing={2}>
        <box spacing={14} halign={Gtk.Align.CENTER} valign={Gtk.Align.CENTER}>
          <label
            cssClasses={["wx-glyph"]}
            label={weatherGlyph(w.code, w.isNight)}
            valign={Gtk.Align.CENTER}
          />
          <label
            cssClasses={["wx-temp"]}
            label={`${w.temp}°`}
            valign={Gtk.Align.CENTER}
          />
        </box>
        <label cssClasses={["wx-desc"]} label={w.desc} halign={Gtk.Align.CENTER} />
      </box>

      <box cssClasses={["wx-metrics"]} spacing={10} halign={Gtk.Align.CENTER} homogeneous>
        <Metric glyph={WIND_GLYPH} value={`${w.windKmph}`} label="km/h" />
        <Metric glyph={HUMIDITY_GLYPH} value={`${w.humidity}%`} label="humid" />
        <Metric glyph={RAIN_GLYPH} value={`${w.rainChance}%`} label="rain" />
        <Metric glyph={FEELS_GLYPH} value={`${w.feelsLike}°`} label="feels" />
      </box>

      <box cssClasses={["wx-hours"]} spacing={6} halign={Gtk.Align.CENTER} homogeneous>
        {w.hours.map((h) => (
          <box
            cssClasses={["wx-hour"]}
            orientation={Gtk.Orientation.VERTICAL}
            spacing={3}
            halign={Gtk.Align.CENTER}
            valign={Gtk.Align.CENTER}
          >
            <label cssClasses={["wx-hour-time"]} label={h.label} halign={Gtk.Align.CENTER} />
            <label
              cssClasses={["wx-hour-glyph"]}
              label={weatherGlyph(h.code, w.isNight)}
              halign={Gtk.Align.CENTER}
            />
            <label cssClasses={["wx-hour-temp"]} label={`${h.temp}°`} halign={Gtk.Align.CENTER} />
          </box>
        ))}
      </box>

      <box cssClasses={["wx-days"]} spacing={4} halign={Gtk.Align.CENTER} homogeneous>
        {w.days.map((d: WeatherDay) => (
          <box
            cssClasses={["wx-day"]}
            orientation={Gtk.Orientation.VERTICAL}
            spacing={3}
            halign={Gtk.Align.CENTER}
            valign={Gtk.Align.CENTER}
          >
            <label cssClasses={["wx-day-label"]} label={d.label} halign={Gtk.Align.CENTER} />
            <label
              cssClasses={["wx-day-glyph"]}
              label={weatherGlyph(d.code, false)}
              halign={Gtk.Align.CENTER}
            />
            <label cssClasses={["wx-day-temps"]} label={`${d.max}°/${d.min}°`} halign={Gtk.Align.CENTER} />
          </box>
        ))}
      </box>
    </box>
  );
}

// In auto mode the setting carries no name, so surface the IP-resolved city from
// the current reading — otherwise the label reads "Auto (IP)" while the forecast
// clearly shows a concrete place.
function locationLabel(setting: LocationSetting, w: WeatherData | null): string {
  if (setting.mode === "fixed") return setting.name;
  return w?.location ? `Auto (IP) · ${w.location}` : "Auto (IP)";
}

function resultLabel(r: LocationResult): string {
  return [r.name, r.admin1, r.country].filter((part) => part !== "").join(", ");
}

// Geocoding search for the weather location. Typing is debounced so a query is
// only sent once the user pauses; a failed lookup falls back to the same empty
// list as a genuine miss rather than surfacing an error.
function LocationSearch() {
  const [query, setQuery] = createState("");
  const [results, setResults] = createState<LocationResult[]>([]);
  let entry: Gtk.Entry | null = null;
  let pending = 0;

  function cancelPending(): void {
    if (pending !== 0) {
      GLib.source_remove(pending);
      pending = 0;
    }
  }

  function onTextChanged(self: Gtk.Entry): void {
    const text = self.text.trim();
    setQuery(text);
    cancelPending();

    if (text === "") {
      setResults([]);
      return;
    }

    pending = GLib.timeout_add(GLib.PRIORITY_DEFAULT, SEARCH_DEBOUNCE_MS, () => {
      pending = 0;
      searchLocations(text)
        .then((found) => setResults(found))
        .catch(() => setResults([]));
      return GLib.SOURCE_REMOVE;
    });
  }

  function choose(target: LocationResult | "auto"): void {
    cancelPending();
    setLocation(target);

    setQuery("");
    setResults([]);
    if (entry) entry.text = "";
  }

  const noResults = createComputed(
    [query, results],
    (q, list) => q !== "" && list.length === 0,
  );

  return (
    <box cssClasses={["wx-search"]} orientation={Gtk.Orientation.VERTICAL} spacing={6}>
      <box spacing={6}>
        <entry
          $={(self) => (entry = self)}
          cssClasses={["wx-search-entry"]}
          hexpand
          placeholderText="Search location…"
          onNotifyText={onTextChanged}
        />
        <button
          cssClasses={["wx-search-auto"]}
          label="Auto (IP)"
          onClicked={() => choose("auto")}
        />
      </box>

      <label
        cssClasses={["wx-search-active"]}
        label={createComputed([currentLocation, weather], locationLabel)}
        halign={Gtk.Align.START}
      />

      <box
        cssClasses={["wx-results"]}
        orientation={Gtk.Orientation.VERTICAL}
        spacing={2}
        visible={results((list) => list.length > 0)}
      >
        <For each={results}>
          {(r: LocationResult) => (
            <button cssClasses={["wx-result"]} onClicked={() => choose(r)}>
              <label label={resultLabel(r)} xalign={0} />
            </button>
          )}
        </For>
      </box>

      <label
        cssClasses={["wx-no-results"]}
        label="No results"
        halign={Gtk.Align.START}
        visible={noResults}
      />
    </box>
  );
}

function WeatherSection() {
  return (
    <box cssClasses={["wx-section"]} orientation={Gtk.Orientation.VERTICAL} hexpand>
      <box halign={Gtk.Align.END} valign={Gtk.Align.START}>
        <button cssClasses={["cal-close"]} onClicked={closeCalendar}>
          <label label={CLOSE_GLYPH} />
        </button>
      </box>

      <LocationSearch />

      <box orientation={Gtk.Orientation.VERTICAL} vexpand valign={Gtk.Align.CENTER}>
        <With value={weather}>
          {(w: WeatherData | null) =>
            w ? (
              <WeatherBody w={w} />
            ) : (
              <box
                orientation={Gtk.Orientation.VERTICAL}
                halign={Gtk.Align.CENTER}
                valign={Gtk.Align.CENTER}
              >
                <box
                  cssClasses={["wx-loading"]}
                  orientation={Gtk.Orientation.VERTICAL}
                  spacing={8}
                  halign={Gtk.Align.CENTER}
                  valign={Gtk.Align.CENTER}
                  visible={weatherStatus((s) => s !== "error")}
                >
                  <Gtk.Spinner
                    $={(self: Gtk.Spinner) => self.start()}
                    halign={Gtk.Align.CENTER}
                  />
                  <label cssClasses={["wx-loading-label"]} label="Loading weather…" />
                </box>
                <label
                  cssClasses={["wx-unavailable"]}
                  label="Weather unavailable"
                  valign={Gtk.Align.CENTER}
                  visible={weatherStatus((s) => s === "error")}
                />
              </box>
            )
          }
        </With>
      </box>
    </box>
  );
}
