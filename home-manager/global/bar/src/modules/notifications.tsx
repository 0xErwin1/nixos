import app from "ags/gtk4/app";
import GLib from "gi://GLib";
import AstalNotifd from "gi://AstalNotifd";
import AstalWp from "gi://AstalWp";
import Pango from "gi://Pango";
import { Astal, Gdk, Gtk } from "ags/gtk4";
import { CARD_VALIGN, EDGE } from "./edge";
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
  WIFI_ACTIVE,
} from "../glyphs";
import {
  notifd,
  groups,
  popupKeys,
  hoveredKey,
  centerVisible,
  dismissPopup,
  dismissGroup,
  dismissAll,
  hoverGroup,
  unhoverGroup,
} from "./notify-state";
import type { Group, Message } from "./notify-history";
import {
  openCenter,
  closeCenter,
  toggleCenter,
  anyPanelOpen,
} from "./dashboard-state";

// ── Notification card ─────────────────────────────────────────────────────────
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

// The live notification behind a message. A message replaced in place, or one
// whose notification was already closed, falls back to the group's newest.
function liveFor(group: Group, message: Message): AstalNotifd.Notification | null {
  return (
    notifd.get_notification(message.notifId) ??
    notifd.get_notification(group.messages[0].notifId)
  );
}

// Clicking a message invokes the default action (if any) and removes the whole
// group — you engaged with the conversation.
function activate(group: Group, message: Message): void {
  const live = liveFor(group, message);
  const actionId = live ? defaultActionId(live) : null;
  if (live && actionId) live.invoke(actionId);
  dismissGroup(group.key);
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

function MessageBody({
  group,
  message,
  lines,
  showTime,
}: {
  group: Group;
  message: Message;
  lines: number;
  showTime: boolean;
}) {
  return (
    <button cssClasses={["notif-body-btn"]} onClicked={() => activate(group, message)}>
      <box spacing={6}>
        <box orientation={Gtk.Orientation.VERTICAL} spacing={3} hexpand>
          {message.image ? (
            <ImageFor
              src={message.image}
              size={48}
              css="notif-image"
              halign={Gtk.Align.START}
            />
          ) : (
            <box visible={false} />
          )}
          {message.body ? (
            <label
              cssClasses={["notif-body"]}
              label={message.body}
              useMarkup
              xalign={0}
              wrap
              maxWidthChars={44}
              lines={lines}
              ellipsize={Pango.EllipsizeMode.END}
            />
          ) : (
            <box visible={false} />
          )}
        </box>
        {showTime ? (
          <label
            cssClasses={["notif-time"]}
            label={relativeTime(message.time)}
            valign={Gtk.Align.START}
          />
        ) : (
          <box visible={false} />
        )}
      </box>
    </button>
  );
}

// One card per group of messages from the same app and sender. A single
// message renders as a plain card; several become an accordion in the center
// that shows the newest message and unfolds every message while hovered. A popup
// always shows the newest message, with the count of the rest.
function GroupCard({
  group,
  variant,
  onClose,
}: {
  group: Group;
  variant: "popup" | "center";
  onClose: () => void;
}) {
  const newest = group.messages[0];
  const count = group.messages.length;
  const collapsible = variant === "center" && count > 1;
  const expanded = hoveredKey((key) => collapsible && key === group.key);

  // Avoid the triple-identity (app name in header + big logo + summary == app
  // name): only show the summary when it adds information over the app name.
  const showSummary =
    group.summary.length > 0 &&
    group.summary.toLowerCase() !== group.appName.toLowerCase();

  const live = notifd.get_notification(newest.notifId);
  const actions = live ? live.actions : [];
  const lines = variant === "popup" ? 5 : 10;

  return (
    <box
      cssClasses={["notif-card", `notif-${group.urgency}`, `notif-${variant}`]}
      spacing={10}
    >
      <Gtk.GestureClick
        button={Gdk.BUTTON_SECONDARY}
        onPressed={() => onClose()}
      />
      <Gtk.EventControllerMotion
        onEnter={() => hoverGroup(group.key)}
        onLeave={() => unhoverGroup(group.key)}
      />
      {group.appIcon ? (
        <ImageFor src={group.appIcon} size={24} css="notif-app-icon" valign={Gtk.Align.START} />
      ) : (
        <box cssClasses={["notif-app-dot"]} valign={Gtk.Align.START} />
      )}

      <box orientation={Gtk.Orientation.VERTICAL} hexpand spacing={3}>
        <box cssClasses={["notif-header"]} spacing={6}>
          <label
            cssClasses={["notif-app"]}
            label={group.appName}
            hexpand
            xalign={0}
            ellipsize={Pango.EllipsizeMode.END}
          />
          {count > 1 ? (
            <label cssClasses={["notif-count"]} label={String(count)} valign={Gtk.Align.CENTER} />
          ) : (
            <box visible={false} />
          )}
          <label cssClasses={["notif-time"]} label={relativeTime(newest.time)} />
          {collapsible ? (
            <label
              cssClasses={["notif-time"]}
              valign={Gtk.Align.CENTER}
              label={expanded((e) => (e ? CHEVRON_UP : CHEVRON_DOWN))}
            />
          ) : (
            <box visible={false} />
          )}
          <button cssClasses={["notif-close"]} valign={Gtk.Align.CENTER} onClicked={onClose}>
            <label label={CLOSE_GLYPH} />
          </button>
        </box>

        {showSummary ? (
          <label
            cssClasses={["notif-summary"]}
            label={group.summary}
            xalign={0}
            wrap
            maxWidthChars={40}
          />
        ) : (
          <box visible={false} />
        )}

        <box visible={expanded((e) => !e)}>
          <MessageBody group={group} message={newest} lines={lines} showTime={false} />
        </box>
        {collapsible ? (
          <box
            cssClasses={["notif-thread"]}
            orientation={Gtk.Orientation.VERTICAL}
            spacing={4}
            visible={expanded}
          >
            {group.messages.map((message) => (
              <MessageBody group={group} message={message} lines={lines} showTime />
            ))}
          </box>
        ) : (
          <box visible={false} />
        )}

        {actions.length > 0 ? (
          <box cssClasses={["notif-actions"]} spacing={6} halign={Gtk.Align.FILL}>
            {actions.map((action) => (
              <button
                cssClasses={["dash-btn", "notif-action"]}
                hexpand
                onClicked={() => {
                  live?.invoke(action.id);
                  dismissGroup(group.key);
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
  const { TOP, BOTTOM, RIGHT } = Astal.WindowAnchor;

  // The window ignores the bar's exclusive zone, so the margin on the bar's
  // side clears it by hand. On a bottom bar the stack is reversed so the newest
  // popup (first in popupKeys) sits next to the bar, as it does on a top bar.
  const onBottom = EDGE === "bottom";
  const shown = createComputed([groups, popupKeys], (list, keys) => {
    const byKey = new Map(list.map((g) => [g.key, g]));
    const ordered = keys.flatMap((key) => byKey.get(key) ?? []);
    return onBottom ? ordered.reverse() : ordered;
  });

  return (
    <window
      name="notification-popups"
      namespace="wl-notifications"
      cssClasses={["notif-popups-window"]}
      anchor={(onBottom ? BOTTOM : TOP) | RIGHT}
      exclusivity={Astal.Exclusivity.IGNORE}
      layer={Astal.Layer.TOP}
      marginTop={EDGE === "top" ? 42 : 8}
      marginBottom={onBottom ? 42 : 8}
      marginRight={8}
      visible={shown((list) => list.length > 0)}
      application={app}
    >
      <box cssClasses={["notif-popups"]} orientation={Gtk.Orientation.VERTICAL} spacing={8}>
        <For each={shown}>
          {(group: Group) => (
            <GroupCard group={group} variant="popup" onClose={() => dismissPopup(group.key)} />
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
    <box cssClasses={["panel-row", "static", "cc-slider-row"]} spacing={10}>
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
    <box cssClasses={["panel-row", "static", "cc-slider-row"]} spacing={10}>
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
      <box cssClasses={["panel-row", "cc-devsel-head"]} spacing={12}>
        <Gtk.GestureClick onPressed={() => setOpen(!open.get())} />
        <label
          cssClasses={["panel-row-icon", "on"]}
          label={headGlyph}
          valign={Gtk.Align.CENTER}
        />
        <box orientation={Gtk.Orientation.VERTICAL} hexpand valign={Gtk.Align.CENTER}>
          <label cssClasses={["panel-row-title"]} label={headLabel} xalign={0} />
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
                  cssClasses={["panel-row-subtitle"]}
                  label={name}
                  xalign={0}
                  maxWidthChars={30}
                  ellipsize={Pango.EllipsizeMode.END}
                />
              );
            }}
          </With>
        </box>
        <label
          cssClasses={["panel-row-trail"]}
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
            {(ep: AstalWp.Endpoint) => {
              const isDefault = createBinding(ep, "isDefault");

              return (
                <button
                  cssClasses={isDefault((d) => ["panel-row", "cc-devsel-item", d ? "active" : ""])}
                  onClicked={() => {
                    ep.set_is_default(true);
                    setOpen(false);
                  }}
                >
                  <box spacing={12}>
                    <label
                      label={ep.description}
                      xalign={0}
                      hexpand
                      ellipsize={Pango.EllipsizeMode.END}
                    />
                    <label cssClasses={["panel-row-check"]} label={WIFI_ACTIVE} visible={isDefault} />
                  </box>
                </button>
              );
            }}
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
  // Control center is built at startup and stays alive while hidden. Skip the
  // subprocess when the center is closed so we do not double the bar's own
  // brightness poll for nothing. One `brightnessctl -m` call per tick.
  const hasBacklight = createPoll(false, 10000, async (prev) => {
    if (!centerVisible.get()) return prev;
    try {
      const out = await execAsync(["brightnessctl", "-m"]);
      const parts = out.trim().split(",");
      return parts.length >= 5 && Number(parts[4]) > 0;
    } catch {
      return prev;
    }
  });

  const brightness = createPoll(0, 3000, async (prev) => {
    if (!centerVisible.get()) return prev;
    try {
      const out = await execAsync(["brightnessctl", "-m"]);
      const parts = out.trim().split(",");
      if (parts.length < 5) return prev;
      const cur = Number(parts[2]);
      const max = Number(parts[4]);
      if (!max) return 0;
      return cur / max;
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
    <box cssClasses={["panel-row", "static", "cc-slider-row"]} spacing={10} visible={hasBacklight}>
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

  const dnd = createBinding(notifd, "dontDisturb");
  const hasNotifications = groups((list) => list.length > 0);

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
        if (!self.isActive) closeCenter();
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
          cssClasses={["panel-card", "control-center-card"]}
          orientation={Gtk.Orientation.HORIZONTAL}
          halign={Gtk.Align.END}
          valign={CARD_VALIGN}
          marginTop={8}
          marginBottom={8}
          marginEnd={8}
          spacing={14}
        >
          {/* Left column: notifications, full height. */}
          <box
            cssClasses={["cc-notif-box"]}
            orientation={Gtk.Orientation.VERTICAL}
            spacing={8}
            vexpand
          >
            <box cssClasses={["panel-header"]} spacing={8}>
              <label cssClasses={["panel-title"]} label="Notifications" hexpand xalign={0} />
              <box cssClasses={["dnd-toggle"]} spacing={6}>
                <label cssClasses={["panel-section-hint"]} label="DND" />
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
                onClicked={dismissAll}
              />
            </box>

            <box cssClasses={["list-area"]} orientation={Gtk.Orientation.VERTICAL} vexpand>
              <box
                vexpand
                halign={Gtk.Align.CENTER}
                valign={Gtk.Align.CENTER}
                visible={hasNotifications((has) => !has)}
              >
                <label cssClasses={["panel-empty"]} label="No notifications" />
              </box>
              <scrolledwindow
                cssClasses={["panel-scroll"]}
                vexpand
                hscrollbarPolicy={Gtk.PolicyType.NEVER}
                vscrollbarPolicy={Gtk.PolicyType.AUTOMATIC}
                visible={hasNotifications}
              >
                <box cssClasses={["notif-list"]} orientation={Gtk.Orientation.VERTICAL} spacing={8}>
                  <For each={groups}>
                    {(group: Group) => (
                      <GroupCard
                        group={group}
                        variant="center"
                        onClose={() => dismissGroup(group.key)}
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
            spacing={14}
          >
            <box cssClasses={["panel-header"]} spacing={8}>
              <label cssClasses={["panel-title"]} label="Control Center" hexpand xalign={0} />
              <button cssClasses={["panel-close"]} onClicked={closeCenter}>
                <label label={CLOSE_GLYPH} />
              </button>
            </box>

            <box orientation={Gtk.Orientation.VERTICAL} spacing={6}>
              <box cssClasses={["panel-section-head"]}>
                <label cssClasses={["panel-section-label"]} label="LEVELS" hexpand xalign={0} />
              </box>
              <box cssClasses={["panel-group"]} orientation={Gtk.Orientation.VERTICAL}>
                <VolumeSlider />
                <MicVolume />
                <BrightnessSlider />
              </box>
            </box>

            <box orientation={Gtk.Orientation.VERTICAL} spacing={6}>
              <box cssClasses={["panel-section-head"]}>
                <label cssClasses={["panel-section-label"]} label="AUDIO DEVICES" hexpand xalign={0} />
              </box>
              <box cssClasses={["panel-group"]} orientation={Gtk.Orientation.VERTICAL}>
                <DeviceSelector audio={audio} kind="output" />
                <DeviceSelector audio={audio} kind="input" />
              </box>
            </box>

            <box orientation={Gtk.Orientation.VERTICAL} spacing={6}>
              <box cssClasses={["panel-section-head"]}>
                <label cssClasses={["panel-section-label"]} label="POWER" hexpand xalign={0} />
              </box>
              <box cssClasses={["panel-group"]} orientation={Gtk.Orientation.VERTICAL}>
                <PowerRow />
              </box>
            </box>
          </box>
        </box>
      </overlay>
    </window>
  );
}

// ── Bar trigger ───────────────────────────────────────────────────────────────
export function NotificationBell() {
  const dnd = createBinding(notifd, "dontDisturb");
  const count = groups((list) => list.reduce((sum, g) => sum + g.messages.length, 0));

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
