import app from "ags/gtk4/app";
import GLib from "gi://GLib";
import AstalNotifd from "gi://AstalNotifd";
import AstalWp from "gi://AstalWp";
import Pango from "gi://Pango";
import { Astal, Gdk, Gtk } from "ags/gtk4";
import {
  For,
  With,
  createBinding,
  createComputed,
  createState,
  onCleanup,
} from "ags";
import { createPoll } from "ags/time";
import { execAsync } from "ags/process";

import {
  BELL,
  BELL_ACTIVE,
  BELL_DND,
  CLOSE_GLYPH,
  LOCK_GLYPH,
  SUSPEND_GLYPH,
  LOGOUT_GLYPH,
  RESTART_GLYPH,
  SHUTDOWN_GLYPH,
  CHEVRON_DOWN,
  CHEVRON_UP,
  volumeGlyph,
  brightnessGlyph,
  MIC_MUTED,
  MIC_UNMUTED,
} from "../glyphs";
import {
  notifd,
  popupIds,
  centerVisible,
  dismissPopup,
} from "./notify-state";
import {
  openCenter,
  closeCenter,
  toggleCenter,
  anyPanelOpen,
} from "./dashboard-state";

// ── Notification card ─────────────────────────────────────────────────────────
function urgencyClass(urgency: AstalNotifd.Urgency): string {
  if (urgency === AstalNotifd.Urgency.CRITICAL) return "critical";
  if (urgency === AstalNotifd.Urgency.LOW) return "low";
  return "normal";
}

function relativeTime(unix: number): string {
  const diff = Math.max(0, Math.floor(Date.now() / 1000) - unix);
  if (diff < 60) return "now";
  if (diff < 3600) return `${Math.floor(diff / 60)}m`;
  if (diff < 86400) return `${Math.floor(diff / 3600)}h`;
  return `${Math.floor(diff / 86400)}d`;
}

// The "default" action routes the app to the relevant place (Slack -> chat,
// etc.) — only if the app supplies it; otherwise fall back to the first action.
function defaultActionId(notification: AstalNotifd.Notification): string | null {
  const actions = notification.actions;
  const def = actions.find((a) => a.id === "default");
  if (def) return def.id;
  return actions.length > 0 ? actions[0].id : null;
}

function ImageFor({
  src,
  size,
  css,
  halign,
  valign,
}: {
  src: string;
  size: number;
  css: string;
  halign?: Gtk.Align;
  valign?: Gtk.Align;
}) {
  const isPath = src.startsWith("/") || src.startsWith("file://");
  const file = src.replace("file://", "");
  return isPath ? (
    <image cssClasses={[css]} file={file} pixelSize={size} halign={halign} valign={valign} />
  ) : (
    <image cssClasses={[css]} iconName={src} pixelSize={size} halign={halign} valign={valign} />
  );
}

function NotificationCard({
  id,
  variant,
  onClose,
}: {
  id: number;
  variant: "popup" | "center";
  onClose: () => void;
}) {
  const notification = notifd.get_notification(id);
  if (!notification) return <box visible={false} />;

  const actions = notification.actions;
  const defaultId = defaultActionId(notification);

  const summary = notification.summary ?? "";
  const appName = notification.appName || "Notification";
  const appIcon = notification.appIcon || "";
  // Avoid the triple-identity (app name in header + big logo + summary == app
  // name): only show the summary when it adds information over the app name.
  const showSummary =
    summary.length > 0 && summary.toLowerCase() !== appName.toLowerCase();

  // Only treat `image` as real content (a screenshot/photo thumbnail) when it is
  // an actual file path — never render the app icon/logo big in the body.
  const contentImage =
    notification.image &&
    (notification.image.startsWith("/") ||
      notification.image.startsWith("file://"))
      ? notification.image
      : "";

  // Clicking the card body invokes the default action (if any) and removes the
  // notification entirely — you engaged with it.
  const activate = () => {
    if (defaultId) notification.invoke(defaultId);
    notification.dismiss();
  };

  return (
    <box
      cssClasses={[
        "notif-card",
        `notif-${urgencyClass(notification.urgency)}`,
        `notif-${variant}`,
      ]}
      spacing={10}
    >
      <Gtk.GestureClick
        button={Gdk.BUTTON_SECONDARY}
        onPressed={() => onClose()}
      />
      {appIcon ? (
        <ImageFor src={appIcon} size={24} css="notif-app-icon" valign={Gtk.Align.START} />
      ) : (
        <box cssClasses={["notif-app-dot"]} valign={Gtk.Align.START} />
      )}

      <box orientation={Gtk.Orientation.VERTICAL} hexpand spacing={3}>
        <box cssClasses={["notif-header"]} spacing={6}>
          <label
            cssClasses={["notif-app"]}
            label={appName}
            hexpand
            xalign={0}
            ellipsize={Pango.EllipsizeMode.END}
          />
          <label cssClasses={["notif-time"]} label={relativeTime(notification.time)} />
          <button cssClasses={["notif-close"]} valign={Gtk.Align.CENTER} onClicked={onClose}>
            <label label={CLOSE_GLYPH} />
          </button>
        </box>

        <button cssClasses={["notif-body-btn"]} onClicked={activate}>
          <box orientation={Gtk.Orientation.VERTICAL} spacing={3}>
            {showSummary ? (
              <label
                cssClasses={["notif-summary"]}
                label={summary}
                xalign={0}
                wrap
                maxWidthChars={40}
              />
            ) : (
              <box visible={false} />
            )}
            {contentImage ? (
              <ImageFor
                src={contentImage}
                size={48}
                css="notif-image"
                halign={Gtk.Align.START}
              />
            ) : (
              <box visible={false} />
            )}
            {notification.body ? (
              <label
                cssClasses={["notif-body"]}
                label={notification.body}
                useMarkup
                xalign={0}
                wrap
                maxWidthChars={44}
                lines={variant === "popup" ? 5 : 10}
                ellipsize={Pango.EllipsizeMode.END}
              />
            ) : (
              <box visible={false} />
            )}
          </box>
        </button>

        {actions.length > 0 ? (
          <box cssClasses={["notif-actions"]} spacing={6} halign={Gtk.Align.FILL}>
            {actions.map((action) => (
              <button
                cssClasses={["dash-btn", "notif-action"]}
                hexpand
                onClicked={() => {
                  notification.invoke(action.id);
                  notification.dismiss();
                }}
              >
                <label label={action.label} />
              </button>
            ))}
          </box>
        ) : (
          <box visible={false} />
        )}
      </box>
    </box>
  );
}

// ── Transient popups ──────────────────────────────────────────────────────────
export function NotificationPopups() {
  const { TOP, RIGHT } = Astal.WindowAnchor;

  return (
    <window
      name="notification-popups"
      namespace="wl-notifications"
      cssClasses={["notif-popups-window"]}
      anchor={TOP | RIGHT}
      exclusivity={Astal.Exclusivity.IGNORE}
      layer={Astal.Layer.TOP}
      marginTop={42}
      marginRight={8}
      visible={popupIds((ids) => ids.length > 0)}
      application={app}
    >
      <box cssClasses={["notif-popups"]} orientation={Gtk.Orientation.VERTICAL} spacing={8}>
        <For each={popupIds}>
          {(id) => (
            <NotificationCard id={id} variant="popup" onClose={() => dismissPopup(id)} />
          )}
        </For>
      </box>
    </window>
  );
}

// ── Quick controls (volume + brightness sliders) ──────────────────────────────
function SpeakerSlider({ speaker }: { speaker: AstalWp.Endpoint }) {
  const volume = createBinding(speaker, "volume");
  const mute = createBinding(speaker, "mute");
  const glyph = createComputed([volume, mute], (v, m) =>
    volumeGlyph(Math.round(v * 100), m),
  );

  // Locally displayed value so the percent tracks the drag instantly (the
  // AstalWp binding updates a beat later); external changes also feed it.
  const [display, setDisplay] = createState(speaker.volume);
  onCleanup(volume.subscribe(() => setDisplay(speaker.volume)));

  return (
    <box cssClasses={["cc-slider-row"]} spacing={10}>
      <box cssClasses={["cc-slider-mute"]} valign={Gtk.Align.CENTER}>
        <Gtk.GestureClick onPressed={() => (speaker.mute = !speaker.mute)} />
        <label
          cssClasses={mute((m) => ["cc-slider-icon", "volume", m ? "muted" : ""])}
          label={glyph}
          valign={Gtk.Align.CENTER}
        />
      </box>
      <slider
        hexpand
        min={0}
        max={1}
        value={volume}
        onChangeValue={(self) => {
          speaker.volume = self.value;
          setDisplay(self.value);
        }}
        valign={Gtk.Align.CENTER}
      />
      <label
        cssClasses={["cc-slider-pct"]}
        label={display((v) => `${Math.round(v * 100)}%`)}
        valign={Gtk.Align.CENTER}
      />
    </box>
  );
}

// Microphone volume + mute, mirroring the speaker slider. The icon doubles as
// the mic mute toggle (red when muted); the new mic-volume slider lets input
// gain be raised without leaving the control center.
function MicSlider({ mic }: { mic: AstalWp.Endpoint }) {
  const volume = createBinding(mic, "volume");
  const mute = createBinding(mic, "mute");

  const [display, setDisplay] = createState(mic.volume);
  onCleanup(volume.subscribe(() => setDisplay(mic.volume)));

  return (
    <box cssClasses={["cc-slider-row"]} spacing={10}>
      <box cssClasses={["cc-slider-mute"]} valign={Gtk.Align.CENTER}>
        <Gtk.GestureClick onPressed={() => (mic.mute = !mic.mute)} />
        <label
          cssClasses={mute((m) => ["cc-slider-icon", "microphone", m ? "muted" : ""])}
          label={mute((m) => (m ? MIC_MUTED : MIC_UNMUTED))}
          valign={Gtk.Align.CENTER}
        />
      </box>
      <slider
        hexpand
        min={0}
        max={1}
        value={volume}
        onChangeValue={(self) => {
          mic.volume = self.value;
          setDisplay(self.value);
        }}
        valign={Gtk.Align.CENTER}
      />
      <label
        cssClasses={["cc-slider-pct"]}
        label={display((v) => `${Math.round(v * 100)}%`)}
        valign={Gtk.Align.CENTER}
      />
    </box>
  );
}

function MicVolume() {
  const mic = createBinding(AstalWp.get_default()!.audio, "defaultMicrophone");
  return (
    <With value={mic}>
      {(m: AstalWp.Endpoint | null) =>
        m ? <MicSlider mic={m} /> : <box visible={false} />
      }
    </With>
  );
}

// Inline output/input device picker: a header row shows the current device and
// toggles a list of the available endpoints below it. Selecting one makes it the
// WirePlumber default. Rendered inline (not a GTK popover) so it stays within the
// layer-shell overlay window.
function DeviceSelector({
  audio,
  kind,
}: {
  audio: AstalWp.Audio;
  kind: "output" | "input";
}) {
  const isOutput = kind === "output";
  const endpoints = createBinding(audio, isOutput ? "speakers" : "microphones");
  const headGlyph = isOutput ? volumeGlyph(100, false) : MIC_UNMUTED;
  const headLabel = isOutput ? "Output" : "Input";

  const [open, setOpen] = createState(false);

  return (
    <box
      cssClasses={["cc-devsel"]}
      orientation={Gtk.Orientation.VERTICAL}
      spacing={4}
    >
      <box cssClasses={["cc-devsel-head"]} spacing={8}>
        <Gtk.GestureClick onPressed={() => setOpen(!open.get())} />
        <label
          cssClasses={["cc-devsel-icon"]}
          label={headGlyph}
          valign={Gtk.Align.CENTER}
        />
        <label
          cssClasses={["cc-devsel-title"]}
          label={headLabel}
          valign={Gtk.Align.CENTER}
        />
        <box hexpand />
        {/* The default endpoint's own description is often empty, and the
            audio.default* property can lag. So show the name of whichever
            endpoint is flagged isDefault — the exact same per-endpoint signal
            the list rows highlight with — so the header always matches the
            selected row. Rebuilt via With when the endpoint set changes. */}
        <With value={endpoints}>
          {(list: AstalWp.Endpoint[]) => {
            const [name, setName] = createState("—");

            const recompute = () => {
              const def = list.find((e) => e.isDefault);
              setName(def?.description ?? "—");
            };
            recompute();
            for (const e of list) {
              onCleanup(createBinding(e, "isDefault").subscribe(recompute));
            }

            return (
              <label
                cssClasses={["cc-devsel-current"]}
                label={name}
                maxWidthChars={26}
                ellipsize={Pango.EllipsizeMode.END}
                valign={Gtk.Align.CENTER}
              />
            );
          }}
        </With>
        <label
          cssClasses={["cc-devsel-chevron"]}
          label={open((o) => (o ? CHEVRON_UP : CHEVRON_DOWN))}
          valign={Gtk.Align.CENTER}
        />
      </box>

      <scrolledwindow
        cssClasses={["cc-devsel-scroll"]}
        visible={open}
        propagateNaturalHeight
        maxContentHeight={200}
        hscrollbarPolicy={Gtk.PolicyType.NEVER}
        vscrollbarPolicy={Gtk.PolicyType.AUTOMATIC}
      >
        <box
          cssClasses={["cc-devsel-list"]}
          orientation={Gtk.Orientation.VERTICAL}
          spacing={2}
        >
          <For each={endpoints}>
            {(ep: AstalWp.Endpoint) => (
              <button
                cssClasses={createBinding(ep, "isDefault")((d) => [
                  "cc-devsel-item",
                  d ? "active" : "",
                ])}
                onClicked={() => {
                  ep.set_is_default(true);
                  setOpen(false);
                }}
              >
                <label
                  label={ep.description}
                  xalign={0}
                  hexpand
                  ellipsize={Pango.EllipsizeMode.END}
                />
              </button>
            )}
          </For>
        </box>
      </scrolledwindow>
    </box>
  );
}

function VolumeSlider() {
  const speaker = createBinding(AstalWp.get_default()!.audio, "defaultSpeaker");
  return (
    <With value={speaker}>
      {(sp: AstalWp.Endpoint | null) =>
        sp ? <SpeakerSlider speaker={sp} /> : <box visible={false} />
      }
    </With>
  );
}

function BrightnessSlider() {
  // Async polls: a synchronous brightnessctl spawn here (the control center is
  // built at startup, so these run continuously) would block the GTK main loop.
  const hasBacklight = createPoll(false, 5000, async (prev) => {
    try {
      return Number(await execAsync(["brightnessctl", "max"])) > 0;
    } catch {
      return prev;
    }
  });

  const brightness = createPoll(0, 2000, async (prev) => {
    try {
      const max = Number(await execAsync(["brightnessctl", "max"]));
      if (!max) return 0;
      return Number(await execAsync(["brightnessctl", "get"])) / max;
    } catch {
      return prev;
    }
  });

  // Locally displayed value so the percent tracks the drag instantly (the label
  // was otherwise bound to the 2s poll and lagged); the poll still feeds it for
  // external changes (brightness keys).
  const [display, setDisplay] = createState(0);
  onCleanup(brightness.subscribe(() => setDisplay(brightness.get())));

  // Only fire brightnessctl when the integer percent actually changes, so a drag
  // does not spawn a process per pixel.
  let lastPercent = -1;
  const setBrightness = (value: number) => {
    setDisplay(value);
    const percent = Math.round(value * 100);
    if (percent === lastPercent) return;
    lastPercent = percent;
    execAsync(["brightnessctl", "set", `${percent}%`]).catch(() => {});
  };

  return (
    <box cssClasses={["cc-slider-row"]} spacing={10} visible={hasBacklight}>
      <label
        cssClasses={["cc-slider-icon", "brightness"]}
        label={display((v) => brightnessGlyph(Math.round(v * 100)))}
        valign={Gtk.Align.CENTER}
      />
      <slider
        hexpand
        min={0.05}
        max={1}
        value={brightness}
        onChangeValue={(self) => setBrightness(self.value)}
        valign={Gtk.Align.CENTER}
      />
      <label
        cssClasses={["cc-slider-pct"]}
        label={display((v) => `${Math.round(v * 100)}%`)}
        valign={Gtk.Align.CENTER}
      />
    </box>
  );
}

// ── Power buttons ─────────────────────────────────────────────────────────────
function PowerButton({
  glyph,
  tooltip,
  command,
  danger = false,
}: {
  glyph: string;
  tooltip: string;
  command: string[];
  danger?: boolean;
}) {
  return (
    <button
      cssClasses={danger ? ["dash-btn", "cc-power-btn", "danger"] : ["dash-btn", "cc-power-btn"]}
      tooltipText={tooltip}
      onClicked={() => {
        execAsync(command).catch(() => {});
        closeCenter();
      }}
    >
      <label cssClasses={["cc-power-glyph"]} label={glyph} />
    </button>
  );
}

function PowerRow() {
  return (
    <box cssClasses={["cc-power"]} spacing={8} halign={Gtk.Align.CENTER}>
      <PowerButton glyph={LOCK_GLYPH} tooltip="Lock" command={["hyprlock"]} />
      <PowerButton glyph={SUSPEND_GLYPH} tooltip="Suspend" command={["systemctl", "suspend"]} />
      <PowerButton glyph={LOGOUT_GLYPH} tooltip="Logout" command={["hyprctl", "dispatch", "exit"]} />
      <PowerButton glyph={RESTART_GLYPH} tooltip="Restart" command={["systemctl", "reboot"]} danger />
      <PowerButton glyph={SHUTDOWN_GLYPH} tooltip="Shutdown" command={["systemctl", "poweroff"]} danger />
    </box>
  );
}

// ── Control center (bell) ─────────────────────────────────────────────────────
export function NotificationCenter() {
  const { TOP, BOTTOM, LEFT, RIGHT } = Astal.WindowAnchor;

  const notifications = createBinding(notifd, "notifications");
  const dnd = createBinding(notifd, "dontDisturb");
  const hasNotifications = notifications((list) => list.length > 0);

  const audio = AstalWp.get_default()!.audio;

  return (
    <window
      name="notification-center"
      namespace="wl-notif-center"
      visible={centerVisible}
      cssClasses={["dashboard-window"]}
      anchor={TOP | BOTTOM | LEFT | RIGHT}
      exclusivity={Astal.Exclusivity.NORMAL}
      layer={Astal.Layer.TOP}
      keymode={Astal.Keymode.ON_DEMAND}
      onNotifyIsActive={(self) => {
        if (!self.get_property("is-active")) closeCenter();
      }}
      application={app}
    >
      <Gtk.EventControllerKey
        onKeyPressed={(_controller, keyval: number) => {
          if (keyval === Gdk.KEY_Escape) closeCenter();
        }}
      />
      <overlay>
        <button cssClasses={["dashboard-backdrop"]} onClicked={closeCenter} />
        <box
          $type="overlay"
          cssClasses={["dashboard-card", "control-center-card"]}
          orientation={Gtk.Orientation.HORIZONTAL}
          halign={Gtk.Align.END}
          valign={Gtk.Align.START}
          spacing={12}
        >
          {/* Left column: notifications, full height. */}
          <box
            cssClasses={["cc-box", "cc-notif-box"]}
            orientation={Gtk.Orientation.VERTICAL}
            spacing={8}
            vexpand
          >
            <box cssClasses={["cc-notif-header"]} spacing={8}>
              <label cssClasses={["cc-title"]} label="Notifications" hexpand xalign={0} />
              <box cssClasses={["dnd-toggle"]} spacing={6}>
                <label cssClasses={["dnd-label"]} label="DND" />
                <switch
                  active={dnd}
                  valign={Gtk.Align.CENTER}
                  onNotifyActive={(self) => {
                    if (self.active !== notifd.dontDisturb)
                      notifd.set_dont_disturb(self.active);
                  }}
                />
              </box>
              <button
                cssClasses={["dash-btn", "danger", "cc-clear"]}
                label="Clear all"
                visible={hasNotifications}
                onClicked={() => {
                  [...notifd.get_notifications()].forEach((n) => n.dismiss());
                }}
              />
            </box>

            <box cssClasses={["list-area"]} orientation={Gtk.Orientation.VERTICAL} vexpand>
              <box
                vexpand
                halign={Gtk.Align.CENTER}
                valign={Gtk.Align.CENTER}
                visible={hasNotifications((has) => !has)}
              >
                <label cssClasses={["empty-label", "list-empty"]} label="No notifications" />
              </box>
              <scrolledwindow
                cssClasses={["list-scroll"]}
                vexpand
                hscrollbarPolicy={Gtk.PolicyType.NEVER}
                vscrollbarPolicy={Gtk.PolicyType.AUTOMATIC}
                visible={hasNotifications}
              >
                <box cssClasses={["notif-list"]} orientation={Gtk.Orientation.VERTICAL} spacing={8}>
                  <For each={notifications((list) => [...list].reverse())}>
                    {(notification) => (
                      <NotificationCard
                        id={notification.id}
                        variant="center"
                        onClose={() => notification.dismiss()}
                      />
                    )}
                  </For>
                </box>
              </scrolledwindow>
            </box>
          </box>

          {/* Right column: quick controls, audio devices, power. */}
          <box
            cssClasses={["cc-col-right"]}
            orientation={Gtk.Orientation.VERTICAL}
            spacing={12}
          >
            <box cssClasses={["dash-header"]} spacing={8}>
              <label cssClasses={["cc-title"]} label="Control Center" hexpand xalign={0} />
              <button cssClasses={["dash-close"]} onClicked={closeCenter}>
                <label label={CLOSE_GLYPH} />
              </button>
            </box>

            <box
              cssClasses={["cc-box", "cc-quick"]}
              orientation={Gtk.Orientation.VERTICAL}
              spacing={8}
            >
              <VolumeSlider />
              <MicVolume />
              <BrightnessSlider />
            </box>

            <box
              cssClasses={["cc-box", "cc-devices"]}
              orientation={Gtk.Orientation.VERTICAL}
              spacing={6}
            >
              <DeviceSelector audio={audio} kind="output" />
              <DeviceSelector audio={audio} kind="input" />
            </box>

            <box cssClasses={["cc-box", "cc-power-box"]}>
              <PowerRow />
            </box>
          </box>
        </box>
      </overlay>
    </window>
  );
}

// ── Bar trigger ───────────────────────────────────────────────────────────────
export function NotificationBell() {
  const notifications = createBinding(notifd, "notifications");
  const dnd = createBinding(notifd, "dontDisturb");
  const count = notifications((list) => list.length);

  const glyph = createComputed([count, dnd], (c, isDnd) =>
    isDnd ? BELL_DND : c > 0 ? BELL_ACTIVE : BELL,
  );
  const iconClasses = createComputed([count, dnd], (c, isDnd) => [
    "control-icon",
    "bell-icon",
    isDnd ? "dnd" : c > 0 ? "has-notifs" : "idle",
  ]);
  const tooltip = createComputed([count, dnd], (c, isDnd) =>
    isDnd
      ? "Do Not Disturb"
      : c > 0
        ? `${c} notification${c === 1 ? "" : "s"}`
        : "No notifications",
  );

  return (
    <box
      cssClasses={["control-item", "bell", "dash-trigger"]}
      tooltipText={tooltip}
      valign={Gtk.Align.CENTER}
    >
      <Gtk.GestureClick onPressed={() => toggleCenter()} />
      <Gtk.EventControllerMotion
        onEnter={() => {
          if (anyPanelOpen()) openCenter();
        }}
      />
      <overlay>
        <label cssClasses={iconClasses} label={glyph} valign={Gtk.Align.CENTER} />
        <label
          $type="overlay"
          cssClasses={["bell-badge"]}
          halign={Gtk.Align.END}
          valign={Gtk.Align.START}
          visible={createComputed([count, dnd], (c, isDnd) => c > 0 && !isDnd)}
          label={count((c) => (c > 9 ? "9+" : String(c)))}
        />
      </overlay>
    </box>
  );
}
