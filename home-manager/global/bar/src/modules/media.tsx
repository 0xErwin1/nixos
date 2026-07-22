import app from "ags/gtk4/app";
import GLib from "gi://GLib";
import Pango from "gi://Pango";
import AstalMpris from "gi://AstalMpris";
import AstalWp from "gi://AstalWp";
import { Astal, Gdk, Gtk } from "ags/gtk4";
import { createBinding, createComputed, createState, onCleanup, For, With } from "ags";
import { createPoll } from "ags/time";

import {
  MEDIA_MUSIC,
  MEDIA_PLAY,
  MEDIA_PAUSE,
  MEDIA_PREV,
  MEDIA_NEXT,
  BT_CONNECTED,
  CLOSE_GLYPH,
} from "../glyphs";
import { mediaVisible, toggleMedia, closeMedia } from "./dashboard-state";
import { measureIslandX } from "./panel-position";

const mpris = AstalMpris.get_default();

// The panel is a separate full-monitor layer window, so it cannot auto-anchor to
// the island widget. Instead, measure the island's x on the monitor when it is
// clicked (measureIslandX) and feed it to the panel card's left margin, so the
// panel drops right under the island. Defaults until the first open.
const [panelX, setPanelX] = createState(8);
let islandWidget: Gtk.Widget | null = null;

const LIVE_LENGTH_THRESHOLD_SECONDS = 7 * 24 * 60 * 60;

function isLiveLength(seconds: number): boolean {
  return Number.isFinite(seconds) && seconds > LIVE_LENGTH_THRESHOLD_SECONDS;
}

function fmtTime(seconds: number): string {
  const s = Number.isFinite(seconds) && seconds > 0 ? Math.floor(seconds) : 0;
  const minutes = Math.floor(s / 60);
  const secondsPart = String(s % 60).padStart(2, "0");

  if (s < 60 * 60) return `${minutes}:${secondsPart}`;

  const hours = Math.floor(s / (60 * 60));
  const minutesPart = String(minutes % 60).padStart(2, "0");
  return `${hours}:${minutesPart}:${secondsPart}`;
}

// Browsers keep an MPRIS player registered after playback ends (stopped, with
// its metadata cleared), so "a player exists" is not the same as "something is
// playing". Prefer a playing player, then any with real metadata; fall back to
// the first so a paused track can still be resumed from the bar.
function selectActive(list: AstalMpris.Player[]): AstalMpris.Player | null {
  if (list.length === 0) return null;

  return (
    list.find((p) => p.playbackStatus === AstalMpris.PlaybackStatus.PLAYING) ??
    list.find((p) => (p.title ?? "").trim().length > 0) ??
    list[0]
  );
}

// The player the island/panel controls. Auto-picks (selectActive) unless the
// user manually pinned one from the panel's source list; a manual pin that
// disappears (app closed) transparently falls back to auto.
const players = createBinding(mpris, "players");
const [manualBus, setManualBus] = createState<string | null>(null);
const activePlayer = createComputed([players, manualBus], (list, bus) => {
  if (bus) {
    const pinned = list.find((p) => p.busName === bus);
    if (pinned) return pinned;
  }
  return selectActive(list);
});

function trackLabel(title: string | null, artist: string | null): string {
  const t = (title ?? "").trim() || "Unknown";
  const a = (artist ?? "").trim();
  return a ? `${t} - ${a}` : t;
}

// A cover-art paintable clipped to a circle: the rounded box has overflow HIDDEN
// (the reliable GTK4 way to clip a child, since inline `css` is unavailable in
// this AGS), so the square image inside is masked to the box's border-radius.
function Cover({ player, size }: { player: AstalMpris.Player; size: number }) {
  const cover = createBinding(player, "coverArt");
  const cls = size >= 96 ? "media-cover-lg" : "media-cover-sm";

  return (
    <box
      cssClasses={[cls]}
      overflow={Gtk.Overflow.HIDDEN}
      halign={Gtk.Align.CENTER}
      valign={Gtk.Align.CENTER}
    >
      <With value={cover}>
        {(path: string) =>
          path ? (
            <image file={path} pixelSize={size} />
          ) : (
            <label cssClasses={["media-cover-fallback"]} label={MEDIA_MUSIC} />
          )
        }
      </With>
    </box>
  );
}

function Controls({
  player,
  variant,
}: {
  player: AstalMpris.Player;
  variant: "sm" | "lg";
}) {
  const status = createBinding(player, "playbackStatus");
  const canNext = createBinding(player, "canGoNext");
  const canPrev = createBinding(player, "canGoPrevious");

  const playGlyph = status((s) =>
    s === AstalMpris.PlaybackStatus.PLAYING ? MEDIA_PAUSE : MEDIA_PLAY,
  );
  const sizeClass = variant === "lg" ? "media-btn-lg" : "media-btn-sm";

  return (
    <box
      cssClasses={["media-controls"]}
      spacing={variant === "lg" ? 14 : 4}
      halign={Gtk.Align.CENTER}
      valign={Gtk.Align.CENTER}
    >
      <button
        cssClasses={["media-btn", sizeClass]}
        sensitive={canPrev}
        onClicked={() => player.previous()}
      >
        <label label={MEDIA_PREV} />
      </button>
      <button
        cssClasses={["media-btn", sizeClass, "media-playpause"]}
        onClicked={() => player.play_pause()}
      >
        <label label={playGlyph} />
      </button>
      <button
        cssClasses={["media-btn", sizeClass]}
        sensitive={canNext}
        onClicked={() => player.next()}
      >
        <label label={MEDIA_NEXT} />
      </button>
    </box>
  );
}

// ── Compact island (revealed only while a player exists) ───────────────────────

function MediaIsland({
  player,
  vertical,
}: {
  player: AstalMpris.Player;
  vertical: boolean;
}) {
  const title = createBinding(player, "title");
  const artist = createBinding(player, "artist");
  const length = createBinding(player, "length");
  const position = createPoll(player.position, 1000, () => player.position);

  const label = createComputed([title, artist], trackLabel);
  const time = createComputed([position, length], (p, l) =>
    isLiveLength(l)
      ? "LIVE"
      : l > 0
        ? `${fmtTime(p)} / ${fmtTime(l)}`
        : fmtTime(p),
  );

  const openPanel = () => {
    if (islandWidget) setPanelX(measureIslandX(islandWidget));
    toggleMedia();
  };

  return (
    <box
      $={(self) => (islandWidget = self)}
      cssClasses={["island", "media"]}
      orientation={
        vertical ? Gtk.Orientation.VERTICAL : Gtk.Orientation.HORIZONTAL
      }
      spacing={vertical ? 4 : 8}
      valign={Gtk.Align.CENTER}
    >
      {/* Only the cover + text open the panel; the control buttons are outside
          this gesture's box, so clicking them acts on playback only. */}
      <box
        cssClasses={["media-open"]}
        orientation={
          vertical ? Gtk.Orientation.VERTICAL : Gtk.Orientation.HORIZONTAL
        }
        spacing={vertical ? 4 : 8}
        valign={Gtk.Align.CENTER}
      >
        <Gtk.GestureClick onPressed={openPanel} />
        <Cover player={player} size={22} />
        {!vertical && (
          <box orientation={Gtk.Orientation.VERTICAL} valign={Gtk.Align.CENTER}>
            <label
              cssClasses={["media-title"]}
              label={label}
              halign={Gtk.Align.START}
              maxWidthChars={22}
              ellipsize={Pango.EllipsizeMode.END}
              singleLineMode
            />
            <label cssClasses={["media-time"]} label={time} halign={Gtk.Align.START} />
          </box>
        )}
      </box>
      <Controls player={player} variant="sm" />
    </box>
  );
}

// Reveal (with the slide animation) only while the active player is not stopped
// and actually has a track loaded — hides the stale "Unknown" leftover a browser
// leaves behind once its media ends.
const HIDE_DELAY_MS = 2000;

function IslandRevealer({
  player,
  vertical,
}: {
  player: AstalMpris.Player;
  vertical: boolean;
}) {
  const status = createBinding(player, "playbackStatus");
  const title = createBinding(player, "title");

  const want = createComputed(
    [status, title],
    (s, t) =>
      s !== AstalMpris.PlaybackStatus.STOPPED && (t ?? "").trim().length > 0,
  );

  // Show instantly, but debounce hiding: while scrolling a feed (e.g. X), the
  // browser's player briefly stops / clears its title between clips, which would
  // otherwise slide the island out and back in on every switch. Only hide once
  // it has genuinely stayed stopped for HIDE_DELAY_MS.
  const [revealed, setRevealed] = createState(want.get());
  let hideTimer = 0;

  const clearHide = () => {
    if (hideTimer !== 0) {
      GLib.source_remove(hideTimer);
      hideTimer = 0;
    }
  };

  onCleanup(
    want.subscribe(() => {
      if (want.get()) {
        clearHide();
        setRevealed(true);
      } else if (hideTimer === 0) {
        hideTimer = GLib.timeout_add(GLib.PRIORITY_DEFAULT, HIDE_DELAY_MS, () => {
          hideTimer = 0;
          setRevealed(false);
          return GLib.SOURCE_REMOVE;
        });
      }
    }),
  );
  onCleanup(clearHide);

  return (
    <revealer
      transitionType={
        vertical
          ? Gtk.RevealerTransitionType.SLIDE_DOWN
          : Gtk.RevealerTransitionType.SLIDE_RIGHT
      }
      transitionDuration={220}
      revealChild={revealed}
    >
      <MediaIsland player={player} vertical={vertical} />
    </revealer>
  );
}

export default function Media({ vertical }: { vertical: boolean }) {
  return (
    <With value={activePlayer}>
      {(p: AstalMpris.Player | null) =>
        p ? (
          <IslandRevealer player={p} vertical={vertical} />
        ) : (
          <box visible={false} />
        )
      }
    </With>
  );
}

// ── Full panel ─────────────────────────────────────────────────────────────────

function DeviceChip({ player }: { player: AstalMpris.Player }) {
  const identity = createBinding(player, "identity");
  const speaker = createBinding(AstalWp.get_default()!.audio, "defaultSpeaker");

  return (
    <box cssClasses={["media-chip-row"]} spacing={8} halign={Gtk.Align.CENTER}>
      <With value={speaker}>
        {(sp: AstalWp.Endpoint | null) =>
          sp ? (
            <box cssClasses={["media-chip"]} spacing={5}>
              <label cssClasses={["media-chip-glyph"]} label={BT_CONNECTED} />
              <label
                cssClasses={["media-chip-label"]}
                label={createBinding(sp, "description")((d) => d ?? "")}
                maxWidthChars={18}
                ellipsize={Pango.EllipsizeMode.END}
              />
            </box>
          ) : (
            <box visible={false} />
          )
        }
      </With>
      <label
        cssClasses={["media-via"]}
        label={identity((id) => `VIA ${id ?? ""}`)}
      />
    </box>
  );
}

function SeekBar({ player }: { player: AstalMpris.Player }) {
  const length = createBinding(player, "length");
  const position = createPoll(player.position, 1000, () => player.position);

  // Local display so the scrubber and the elapsed label track the drag instantly
  // instead of snapping back until the next poll tick.
  const [display, setDisplay] = createState(player.position);
  onCleanup(position.subscribe(() => setDisplay(position.get())));

  return (
    <With value={length}>
      {(l: number) =>
        isLiveLength(l) ? (
          <box cssClasses={["media-seek"]}>
            <label
              cssClasses={["media-seek-time"]}
              label="LIVE"
              halign={Gtk.Align.START}
            />
          </box>
        ) : l > 0 ? (
          <box
            cssClasses={["media-seek"]}
            orientation={Gtk.Orientation.VERTICAL}
            spacing={4}
          >
            <slider
              cssClasses={["media-slider"]}
              hexpand
              min={0}
              max={l}
              value={display}
              onChangeValue={(self: Gtk.Scale) => {
                player.position = self.value;
                setDisplay(self.value);
              }}
            />
            <box>
              <label
                cssClasses={["media-seek-time"]}
                label={display((p) => fmtTime(p))}
                halign={Gtk.Align.START}
                hexpand
              />
              <label
                cssClasses={["media-seek-time"]}
                label={fmtTime(l)}
                halign={Gtk.Align.END}
              />
            </box>
          </box>
        ) : (
          <box visible={false} />
        )
      }
    </With>
  );
}

function MediaPanelBody({ player }: { player: AstalMpris.Player }) {
  const title = createBinding(player, "title");
  const artist = createBinding(player, "artist");

  return (
    <box
      cssClasses={["media-body"]}
      orientation={Gtk.Orientation.HORIZONTAL}
      spacing={20}
      valign={Gtk.Align.CENTER}
    >
      <Cover player={player} size={150} />

      <box
        cssClasses={["media-info"]}
        orientation={Gtk.Orientation.VERTICAL}
        spacing={8}
        hexpand
        valign={Gtk.Align.CENTER}
      >
        <label
          cssClasses={["media-panel-title"]}
          label={title((t) => (t ?? "").trim() || "Unknown")}
          halign={Gtk.Align.START}
          maxWidthChars={28}
          ellipsize={Pango.EllipsizeMode.END}
        />
        <label
          cssClasses={["media-panel-artist"]}
          label={artist((a) => `BY ${(a ?? "").trim() || "Unknown"}`)}
          halign={Gtk.Align.START}
        />

        <DeviceChip player={player} />
        <SeekBar player={player} />
        <Controls player={player} variant="lg" />
      </box>
    </box>
  );
}

// Manual source picker, shown only when more than one player is registered.
// "Auto" clears the pin (falls back to selectActive); each source pins that
// player. The dot turns green while that source is playing.
function PlayerSelector() {
  return (
    <box
      cssClasses={["media-sources"]}
      spacing={6}
      halign={Gtk.Align.CENTER}
      visible={players((list) => list.length > 1)}
    >
      <button
        cssClasses={manualBus((b) => ["media-src", b === null ? "active" : ""])}
        onClicked={() => setManualBus(null)}
      >
        <label label="Auto" />
      </button>
      <For each={players}>
        {(p: AstalMpris.Player) => {
          const status = createBinding(p, "playbackStatus");
          return (
            <button
              cssClasses={manualBus((b) => [
                "media-src",
                b === p.busName ? "active" : "",
              ])}
              onClicked={() => setManualBus(p.busName)}
            >
              <box spacing={6} valign={Gtk.Align.CENTER}>
                <box
                  cssClasses={status((s) => [
                    "media-src-dot",
                    s === AstalMpris.PlaybackStatus.PLAYING ? "playing" : "",
                  ])}
                />
                <label label={p.identity ?? "Player"} />
              </box>
            </button>
          );
        }}
      </For>
    </box>
  );
}

export function MediaPanel() {
  const { TOP, BOTTOM, LEFT, RIGHT } = Astal.WindowAnchor;

  return (
    <window
      name="media-panel"
      namespace="wl-media"
      visible={mediaVisible}
      cssClasses={["media-window"]}
      anchor={TOP | BOTTOM | LEFT | RIGHT}
      exclusivity={Astal.Exclusivity.NORMAL}
      layer={Astal.Layer.TOP}
      keymode={Astal.Keymode.ON_DEMAND}
      onNotifyIsActive={(self) => {
        if (!self.isActive) closeMedia();
      }}
      application={app}
    >
      <Gtk.EventControllerKey
        onKeyPressed={(_c, keyval: number) => {
          if (keyval === Gdk.KEY_Escape) closeMedia();
        }}
      />
      <overlay>
        <button cssClasses={["media-backdrop"]} onClicked={closeMedia} />
        <box
          $type="overlay"
          cssClasses={["media-card"]}
          orientation={Gtk.Orientation.VERTICAL}
          halign={Gtk.Align.START}
          valign={Gtk.Align.START}
          marginTop={8}
          marginStart={panelX}
          spacing={10}
        >
          <box halign={Gtk.Align.END}>
            <button cssClasses={["media-close"]} onClicked={closeMedia}>
              <label label={CLOSE_GLYPH} />
            </button>
          </box>
          <PlayerSelector />
          <With value={activePlayer}>
            {(p: AstalMpris.Player | null) =>
              p ? (
                <MediaPanelBody player={p} />
              ) : (
                <label cssClasses={["media-empty"]} label="Nothing playing" />
              )
            }
          </With>
        </box>
      </overlay>
    </window>
  );
}
