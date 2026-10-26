// The bar's own notification history, kept apart from the daemon's store.
//
// The daemon holds one object per notification id, and a sender that passes
// `replaces_id` (Chromium does, per chat tag: WhatsApp Web, Teams, Slack) gets
// its previous object overwritten. Reading the daemon's list therefore shows
// only the last message of a conversation. This store snapshots every arrival
// instead, groups messages by app and sender, and collapses the same
// notification when a sender delivers it twice (Teams and Slack sometimes do).
//
// A duplicate is told apart from a genuine repeat by arrival time only: the
// daemon does not expose the D-Bus sender, which would distinguish one buggy
// delivery from two runs of the same command. Identical notifications that
// arrive within the duplicate window therefore collapse even when they come
// from separate runs.
//
// Pure TypeScript with no GObject imports, so it runs under `node --test`.

export type Urgency = "low" | "normal" | "critical";

export interface Incoming {
  // Daemon id of the live notification this message came from. Several
  // messages share one id when the sender replaced it in place.
  notifId: number;
  appName: string;
  appIcon: string;
  summary: string;
  body: string;
  image: string;
  urgency: Urgency;
  // Action ids, part of a notification's identity for duplicate detection.
  actions: string[];
  // Unix seconds, as reported by the daemon; shown to the user.
  time: number;
  // Arrival in milliseconds. The daemon's `time` has a resolution of one
  // second, too coarse to tell a double delivery from a quick repeat.
  arrivedMs: number;
}

export interface Message extends Incoming {
  // Unique per stored message, unlike notifId.
  key: number;
  groupKey: string;
}

export interface Group {
  key: string;
  appName: string;
  appIcon: string;
  summary: string;
  urgency: Urgency;
  // Newest first.
  messages: Message[];
}

export interface AddResult {
  message: Message;
  // True when the arrival repeated a stored message and was not added.
  duplicate: boolean;
  // Live notifications no stored message references anymore; the caller
  // dismisses them so the daemon's store does not grow behind the history.
  orphaned: number[];
}

export interface HistoryOptions {
  maxStored: number;
  maxAgeSeconds: number;
  duplicateWindowMs: number;
}

const SEVERITY: Record<Urgency, number> = { low: 0, normal: 1, critical: 2 };

function sameContent(a: Incoming, b: Incoming): boolean {
  return (
    a.body.trim() === b.body.trim() &&
    a.appIcon === b.appIcon &&
    a.image === b.image &&
    a.urgency === b.urgency &&
    a.actions.join("\u0000") === b.actions.join("\u0000")
  );
}

export function groupKeyOf(message: Pick<Incoming, "appName" | "summary">): string {
  return `${message.appName.toLowerCase()}\u0000${message.summary}`;
}

export class NotificationHistory {
  // Newest first.
  private messages: Message[] = [];
  private nextKey = 1;
  private readonly options: HistoryOptions;

  constructor(options: HistoryOptions) {
    this.options = options;
  }

  get size(): number {
    return this.messages.length;
  }

  add(incoming: Incoming): AddResult {
    const groupKey = groupKeyOf(incoming);

    const original = this.messages.find(
      (m) =>
        m.groupKey === groupKey &&
        Math.abs(incoming.arrivedMs - m.arrivedMs) <= this.options.duplicateWindowMs &&
        sameContent(m, incoming),
    );
    if (original) {
      const previousId = original.notifId;
      original.notifId = incoming.notifId;
      return {
        message: original,
        duplicate: true,
        orphaned: this.unreferenced([previousId]),
      };
    }

    const message: Message = { ...incoming, key: this.nextKey++, groupKey };
    this.messages.unshift(message);
    return { message, duplicate: false, orphaned: this.prune(incoming.time) };
  }

  // A notification left the daemon. When the user dismissed it, every message
  // it carried goes too. When its sender closed it, the messages stay: Chromium
  // closes a web notification right before sending the next one from the same
  // chat (WhatsApp Web does this for every message), so treating that close as
  // "read" would leave only the newest message.
  resolveNotification(notifId: number, { closedBySender }: { closedBySender: boolean }): boolean {
    if (closedBySender) return false;
    return this.removeNotification(notifId);
  }

  removeNotification(notifId: number): boolean {
    const before = this.messages.length;
    this.messages = this.messages.filter((m) => m.notifId !== notifId);
    return this.messages.length !== before;
  }

  // Returns the live notifications the group referenced, for dismissal.
  removeGroup(groupKey: string): number[] {
    const removed = this.messages.filter((m) => m.groupKey === groupKey);
    this.messages = this.messages.filter((m) => m.groupKey !== groupKey);
    return this.unreferenced(removed.map((m) => m.notifId));
  }

  clear(): number[] {
    const ids = this.messages.map((m) => m.notifId);
    this.messages = [];
    return unique(ids);
  }

  // Drops messages past the age limit, then the oldest beyond the count limit.
  prune(now: number): number[] {
    const kept = this.messages
      .filter((m) => now - m.time <= this.options.maxAgeSeconds)
      .slice(0, this.options.maxStored);
    const dropped = this.messages.filter((m) => !kept.includes(m));
    this.messages = kept;
    return this.unreferenced(dropped.map((m) => m.notifId));
  }

  // Local files the stored messages display, so the caller can delete copies
  // no message uses anymore. Icon names are not files and are left out.
  referencedFiles(): Set<string> {
    const files = new Set<string>();
    for (const m of this.messages) {
      for (const src of [m.appIcon, m.image]) {
        if (isFilePath(src)) files.add(src.replace(/^file:\/\//, ""));
      }
    }
    return files;
  }

  groups(): Group[] {
    const byKey = new Map<string, Group>();
    for (const message of this.messages) {
      const group = byKey.get(message.groupKey);
      if (!group) {
        byKey.set(message.groupKey, {
          key: message.groupKey,
          appName: message.appName,
          appIcon: message.appIcon,
          summary: message.summary,
          urgency: message.urgency,
          messages: [message],
        });
        continue;
      }
      group.messages.push(message);
      if (SEVERITY[message.urgency] > SEVERITY[group.urgency]) {
        group.urgency = message.urgency;
      }
    }
    return [...byKey.values()];
  }

  private unreferenced(ids: number[]): number[] {
    return unique(ids).filter((id) => !this.messages.some((m) => m.notifId === id));
  }
}

export function isFilePath(src: string): boolean {
  return src.startsWith("/") || src.startsWith("file://");
}

function unique(ids: number[]): number[] {
  return [...new Set(ids)];
}
