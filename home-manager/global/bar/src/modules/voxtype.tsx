import GLib from "gi://GLib";
import { Gtk } from "ags/gtk4";
import { createState } from "ags";
import { createPoll } from "ags/time";
import { subprocess } from "ags/process";

export type VoxState = "idle" | "recording" | "transcribing" | "stopped";

const VOX_RECORDING = "\u{f036c}";
const VOX_TRANSCRIBING = "\u{f01d9}";
const WAVE_BARS = 7;

const KNOWN_STATES: VoxState[] = ["idle", "recording", "transcribing", "stopped"];

const [voxState, setVoxState] = createState<VoxState>("idle");

function parseState(line: string): VoxState | null {
  try {
    const parsed = JSON.parse(line);
    const raw = String(parsed.class ?? parsed.alt ?? "");
    if (KNOWN_STATES.includes(raw as VoxState)) return raw as VoxState;
  } catch {
    // Non-JSON line (e.g. the plain-word state fallback): accept known words.
    const raw = line.trim();
    if (KNOWN_STATES.includes(raw as VoxState)) return raw as VoxState;
  }
  return null;
}

// Long-running follower that emits one JSON line per voxtype state change. If it
// exits (service restart, voxtype missing) we drop to idle and respawn shortly
// after so the widget recovers on its own. voxtype is inherited from the user's
// session PATH (it is a systemd user service), like hyprctl/brightnessctl.
function watchVoxtype(): void {
  const respawn = () => {
    GLib.timeout_add(GLib.PRIORITY_DEFAULT, 2000, () => {
      watchVoxtype();
      return GLib.SOURCE_REMOVE;
    });
  };

  try {
    const proc = subprocess(
      ["voxtype", "status", "--follow", "--format", "json"],
      (out) => {
        const state = parseState(out);
        if (state) setVoxState(state);
      },
      () => {},
    );

    proc.connect("exit", () => {
      setVoxState("idle");
      respawn();
    });
  } catch {
    respawn();
  }
}

watchVoxtype();

// Elapsed time for the current phase: reset the monotonic stamp on each entry
// into "recording" or "transcribing", then format M:SS on a 1s poll. voxtype
// exposes no transcription-progress percentage, so the ticking transcribe timer
// is the honest signal for "how long is it taking / did it get stuck".
let phaseStart = 0;

voxState.subscribe(() => {
  const state = voxState.get();
  if (state === "recording" || state === "transcribing") {
    phaseStart = GLib.get_monotonic_time();
  } else {
    phaseStart = 0;
  }
});

const elapsed = createPoll("0:00", 1000, () => {
  if (phaseStart === 0) return "0:00";

  const seconds = Math.floor(
    (GLib.get_monotonic_time() - phaseStart) / 1_000_000,
  );
  const minutes = Math.floor(seconds / 60);
  const rest = seconds % 60;

  return `${minutes}:${rest.toString().padStart(2, "0")}`;
});

function Waveform() {
  return (
    <box cssClasses={["vox-wave"]} valign={Gtk.Align.CENTER}>
      {Array.from({ length: WAVE_BARS }, (_, i) => (
        <box cssClasses={["vox-bar", `vox-bar-${i}`]} valign={Gtk.Align.CENTER} />
      ))}
    </box>
  );
}

export default function Voxtype({ vertical }: { vertical: boolean }) {
  const revealed = voxState((s) => s === "recording" || s === "transcribing");
  const icon = voxState((s) =>
    s === "transcribing" ? VOX_TRANSCRIBING : VOX_RECORDING,
  );
  const islandClasses = voxState((s) => ["island", "voxtype", s]);

  return (
    <revealer
      transitionType={
        vertical
          ? Gtk.RevealerTransitionType.SLIDE_DOWN
          : Gtk.RevealerTransitionType.SLIDE_LEFT
      }
      transitionDuration={200}
      revealChild={revealed}
    >
      <box
        cssClasses={islandClasses}
        orientation={
          vertical ? Gtk.Orientation.VERTICAL : Gtk.Orientation.HORIZONTAL
        }
        spacing={vertical ? 4 : 8}
        valign={Gtk.Align.CENTER}
      >
        <label cssClasses={["vox-icon"]} label={icon} valign={Gtk.Align.CENTER} />
        {!vertical && <Waveform />}
        <label
          cssClasses={["vox-elapsed"]}
          label={elapsed}
          valign={Gtk.Align.CENTER}
        />
      </box>
    </revealer>
  );
}
