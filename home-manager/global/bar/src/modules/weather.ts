import GLib from "gi://GLib";
import { createState } from "ags";
import { execAsync } from "ags/process";

// Weather from Open-Meteo (no API key). The location is either resolved from the
// request IP (auto mode) or pinned to a place picked through the geocoding
// search, and is persisted between runs. One shared reactive value drives both
// the bar's mini-weather (next to the date) and the calendar panel, polled on a
// slow timer so the widget stays cheap.

export interface WeatherHour {
  label: string;
  temp: number;
  code: number;
  rainChance: number;
}

export interface WeatherDay {
  label: string;
  max: number;
  min: number;
  code: number;
}

export interface WeatherData {
  location: string;
  temp: number;
  feelsLike: number;
  desc: string;
  code: number;
  humidity: number;
  windKmph: number;
  rainChance: number;
  isNight: boolean;
  hours: WeatherHour[];
  days: WeatherDay[];
}

export interface LocationResult {
  name: string;
  admin1: string;
  country: string;
  latitude: number;
  longitude: number;
}

export type LocationSetting =
  | { mode: "auto" }
  | { mode: "fixed"; name: string; lat: number; lon: number };

const REFRESH_SECONDS = 900;
const HOURS_SHOWN = 6;
const FORECAST_DAYS = 7;

const CONFIG_DIR = `${GLib.get_user_config_dir()}/wl-bar`;
const CONFIG_PATH = `${CONFIG_DIR}/weather-location.json`;
// Previous location before the bar was renamed from epsilon-bar; still read as a
// fallback so an existing saved location survives the rename.
const LEGACY_CONFIG_PATH = `${GLib.get_user_config_dir()}/epsilon-bar/weather-location.json`;

const DAY_NAMES = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"];

const WMO_DESC: Record<number, string> = {
  0: "Clear",
  1: "Mainly clear",
  2: "Partly cloudy",
  3: "Overcast",
  45: "Fog",
  48: "Fog",
  51: "Drizzle",
  53: "Drizzle",
  55: "Drizzle",
  56: "Freezing drizzle",
  57: "Freezing drizzle",
  61: "Rain",
  63: "Rain",
  65: "Rain",
  66: "Freezing rain",
  67: "Freezing rain",
  71: "Snow",
  73: "Snow",
  75: "Snow",
  77: "Snow grains",
  80: "Rain showers",
  81: "Rain showers",
  82: "Rain showers",
  85: "Snow showers",
  86: "Snow showers",
  95: "Thunderstorm",
  96: "Thunderstorm with hail",
  99: "Thunderstorm with hail",
};

function round(value: unknown): number {
  const n = Math.round(Number(value));
  return Number.isFinite(n) ? n : 0;
}

function describe(code: number): string {
  return WMO_DESC[code] ?? "Unknown";
}

function curl(url: string): Promise<string> {
  return execAsync(["curl", "-sf", "--max-time", "20", url]);
}

// ── Persisted location ────────────────────────────────────────────────────────

function readSetting(): LocationSetting {
  try {
    let result = GLib.file_get_contents(CONFIG_PATH);
    if (!result[0]) result = GLib.file_get_contents(LEGACY_CONFIG_PATH);

    const ok = result[0];
    const contents = result[1];
    if (!ok) return { mode: "auto" };

    const parsed = JSON.parse(new TextDecoder().decode(contents));
    if (
      parsed?.mode === "fixed" &&
      typeof parsed.name === "string" &&
      Number.isFinite(parsed.lat) &&
      Number.isFinite(parsed.lon)
    ) {
      return { mode: "fixed", name: parsed.name, lat: parsed.lat, lon: parsed.lon };
    }

    return { mode: "auto" };
  } catch {
    return { mode: "auto" };
  }
}

function writeSetting(setting: LocationSetting): void {
  try {
    GLib.mkdir_with_parents(CONFIG_DIR, 0o755);
    GLib.file_set_contents(CONFIG_PATH, JSON.stringify(setting));
  } catch {
    // A read-only config dir must not take the widget down; the choice simply
    // does not survive a restart.
  }
}

const [currentLocation, setCurrentLocation] = createState<LocationSetting>(readSetting());

// ── Fetching ──────────────────────────────────────────────────────────────────

interface Coords {
  lat: number;
  lon: number;
  name: string;
}

function coordsFrom(lat: unknown, lon: unknown, name: unknown): Coords | null {
  const latN = Number(lat);
  const lonN = Number(lon);
  if (!Number.isFinite(latN) || !Number.isFinite(lonN)) return null;

  return { lat: latN, lon: lonN, name: String(name ?? "") };
}

// ipapi.co (the obvious pick) intermittently returns an empty body on its free
// tier, which reads as "no location" and silently disables auto mode. Try a
// couple of key-free HTTPS providers in order so one flaky endpoint does not
// take auto mode down. geojs returns lat/lon as strings; Number() handles both.
const IP_GEO_PROVIDERS: { url: string; extract: (j: any) => Coords | null }[] = [
  {
    url: "https://ipwho.is/",
    extract: (j) =>
      j?.success === false ? null : coordsFrom(j.latitude, j.longitude, j.city),
  },
  {
    url: "https://get.geojs.io/v1/ip/geo.json",
    extract: (j) => coordsFrom(j.latitude, j.longitude, j.city),
  },
];

async function geolocateByIp(): Promise<Coords> {
  for (const provider of IP_GEO_PROVIDERS) {
    try {
      const coords = provider.extract(JSON.parse(await curl(provider.url)));
      if (coords) return coords;
    } catch {
      // Fall through to the next provider.
    }
  }

  throw new Error("no IP geolocation provider returned coordinates");
}

async function resolveCoords(setting: LocationSetting): Promise<Coords> {
  if (setting.mode === "fixed") {
    return { lat: setting.lat, lon: setting.lon, name: setting.name };
  }

  return geolocateByIp();
}

function forecastUrl(coords: Coords): string {
  return (
    "https://api.open-meteo.com/v1/forecast" +
    `?latitude=${coords.lat}&longitude=${coords.lon}` +
    "&current=temperature_2m,apparent_temperature,relative_humidity_2m,weather_code,wind_speed_10m,is_day" +
    "&hourly=temperature_2m,weather_code,precipitation_probability" +
    "&daily=weather_code,temperature_2m_max,temperature_2m_min" +
    `&timezone=auto&forecast_days=${FORECAST_DAYS}`
  );
}

// Open-Meteo returns the hourly series as parallel arrays keyed by an ISO
// "YYYY-MM-DDTHH:MM" local timestamp; take the HOURS_SHOWN entries starting at
// the current hour.
function parseHours(hourly: any): WeatherHour[] {
  const times: string[] = hourly?.time ?? [];
  const nowStamp = GLib.DateTime.new_now_local().format("%Y-%m-%dT%H:00") ?? "";

  let start = times.findIndex((t) => t >= nowStamp);
  if (start < 0) start = 0;

  const hours: WeatherHour[] = [];
  for (let i = start; i < times.length && hours.length < HOURS_SHOWN; i++) {
    hours.push({
      label: `${times[i].slice(11, 13)}:00`,
      temp: round(hourly.temperature_2m?.[i]),
      code: round(hourly.weather_code?.[i]),
      rainChance: round(hourly.precipitation_probability?.[i]),
    });
  }

  return hours;
}

function parseDays(daily: any): WeatherDay[] {
  const times: string[] = daily?.time ?? [];
  const today = GLib.DateTime.new_now_local().format("%Y-%m-%d");

  return times.map((date, i) => ({
    label:
      date === today
        ? "Today"
        : DAY_NAMES[new Date(`${date}T00:00:00`).getDay()] ?? date,
    max: round(daily.temperature_2m_max?.[i]),
    min: round(daily.temperature_2m_min?.[i]),
    code: round(daily.weather_code?.[i]),
  }));
}

function parseWeather(rawJson: string, locationName: string): WeatherData | null {
  const j = JSON.parse(rawJson);

  const cur = j.current;
  if (!cur) return null;

  const code = round(cur.weather_code);
  const hours = parseHours(j.hourly);

  return {
    location: locationName,
    temp: round(cur.temperature_2m),
    feelsLike: round(cur.apparent_temperature),
    desc: describe(code),
    code,
    humidity: round(cur.relative_humidity_2m),
    windKmph: round(cur.wind_speed_10m),
    rainChance: hours[0]?.rainChance ?? 0,
    isNight: cur.is_day === 0,
    hours,
    days: parseDays(j.daily),
  };
}

export type WeatherStatus = "loading" | "ready" | "error";

const [weather, setWeather] = createState<WeatherData | null>(null);
const [weatherStatus, setWeatherStatus] = createState<WeatherStatus>("loading");

// Keep the last good reading on a transient failure (offline, DNS, upstream 5xx)
// so the widget does not blank out between successful polls; the status only
// drives the placeholder shown before the first successful reading arrives.
function refresh(): void {
  resolveCoords(currentLocation.get())
    .then(async (coords) => parseWeather(await curl(forecastUrl(coords)), coords.name))
    .then((parsed) => {
      if (parsed) {
        setWeather(parsed);
        setWeatherStatus("ready");
      } else {
        setWeatherStatus("error");
      }
    })
    .catch(() => setWeatherStatus("error"));
}

export async function searchLocations(query: string): Promise<LocationResult[]> {
  const trimmed = query.trim();
  if (!trimmed) return [];

  const url =
    "https://geocoding-api.open-meteo.com/v1/search" +
    `?name=${GLib.Uri.escape_string(trimmed, null, false)}` +
    "&count=8&language=es&format=json";

  const j = JSON.parse(await curl(url));

  return (j.results ?? []).map(
    (r: any): LocationResult => ({
      name: String(r.name ?? ""),
      admin1: String(r.admin1 ?? ""),
      country: String(r.country ?? r.country_code ?? ""),
      latitude: Number(r.latitude),
      longitude: Number(r.longitude),
    }),
  );
}

export function setLocation(target: LocationResult | "auto"): void {
  const setting: LocationSetting =
    target === "auto"
      ? { mode: "auto" }
      : {
          mode: "fixed",
          name: target.name,
          lat: target.latitude,
          lon: target.longitude,
        };

  setCurrentLocation(setting);
  writeSetting(setting);
  refresh();
}

refresh();
GLib.timeout_add_seconds(GLib.PRIORITY_DEFAULT, REFRESH_SECONDS, () => {
  refresh();
  return GLib.SOURCE_CONTINUE;
});

export { weather, weatherStatus, currentLocation };
