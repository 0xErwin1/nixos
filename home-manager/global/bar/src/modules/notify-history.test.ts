// Run with: node --test home-manager/global/bar/src/modules/notify-history.test.ts
import { test } from "node:test";
import assert from "node:assert/strict";

import { NotificationHistory, type Incoming } from "./notify-history.ts";

function incoming(overrides: Partial<Incoming> = {}): Incoming {
  return {
    notifId: 1,
    appName: "Brave",
    appIcon: "brave",
    summary: "Alice",
    body: "hi",
    image: "",
    urgency: "normal",
    actions: [],
    time: 1_000,
    ...overrides,
    arrivedMs: overrides.arrivedMs ?? (overrides.time ?? 1_000) * 1_000,
  };
}

function history(): NotificationHistory {
  return new NotificationHistory({
    maxStored: 50,
    maxAgeSeconds: 3_600,
    duplicateWindowMs: 1_000,
  });
}

test("a notification replaced in place keeps every earlier message", () => {
  const h = history();
  h.add(incoming({ body: "first", time: 1_000 }));
  h.add(incoming({ body: "second", time: 1_010 }));

  const groups = h.groups();
  assert.equal(groups.length, 1);
  assert.deepEqual(
    groups[0].messages.map((m) => m.body),
    ["second", "first"],
  );
  assert.equal(h.size, 2);
});

test("messages group by app and sender, newest group first", () => {
  const h = history();
  h.add(incoming({ notifId: 1, summary: "Alice", body: "a1", time: 1_000 }));
  h.add(incoming({ notifId: 2, summary: "Bob", body: "b1", time: 1_005 }));
  h.add(incoming({ notifId: 3, summary: "Alice", body: "a2", time: 1_010 }));
  h.add(incoming({ notifId: 4, appName: "Slack", summary: "Alice", body: "s1", time: 1_020 }));

  const groups = h.groups();
  assert.deepEqual(
    groups.map((g) => [g.appName, g.summary, g.messages.map((m) => m.body)]),
    [
      ["Slack", "Alice", ["s1"]],
      ["Brave", "Alice", ["a2", "a1"]],
      ["Brave", "Bob", ["b1"]],
    ],
  );
});

test("the same notification delivered twice within the window is a duplicate", () => {
  const h = history();
  h.add(incoming({ notifId: 1, body: "standup?", arrivedMs: 1_000_000 }));
  const result = h.add(incoming({ notifId: 2, body: "standup?", arrivedMs: 1_000_300 }));

  assert.equal(result.duplicate, true);
  assert.equal(h.size, 1);
  // The stored message now points at the live notification, and the one it
  // used to point at is no longer referenced by anything.
  assert.equal(h.groups()[0].messages[0].notifId, 2);
  assert.deepEqual(result.orphaned, [1]);
});

test("a duplicate replacing in place orphans nothing", () => {
  const h = history();
  h.add(incoming({ notifId: 7, body: "same", arrivedMs: 1_000_000 }));
  const result = h.add(incoming({ notifId: 7, body: "same", arrivedMs: 1_000_100 }));

  assert.equal(result.duplicate, true);
  assert.deepEqual(result.orphaned, []);
  assert.equal(h.size, 1);
});

test("an identical notification from a later run is a new message", () => {
  const h = history();
  h.add(incoming({ notifId: 1, appName: "satty", summary: "Copied", arrivedMs: 1_000_000 }));
  const result = h.add(
    incoming({ notifId: 2, appName: "satty", summary: "Copied", arrivedMs: 1_002_500 }),
  );

  assert.equal(result.duplicate, false);
  assert.equal(h.size, 2);
});

test("the same text with a different image or icon is not a duplicate", () => {
  const h = history();
  h.add(incoming({ notifId: 1, image: "/tmp/a.png", arrivedMs: 1_000_000 }));
  h.add(incoming({ notifId: 2, image: "/tmp/b.png", arrivedMs: 1_000_100 }));
  h.add(incoming({ notifId: 3, image: "/tmp/b.png", appIcon: "other", arrivedMs: 1_000_200 }));

  assert.equal(h.size, 3);
});

test("the same text with different actions is not a duplicate", () => {
  const h = history();
  h.add(incoming({ notifId: 1, actions: ["default"], arrivedMs: 1_000_000 }));
  h.add(incoming({ notifId: 2, actions: ["open"], arrivedMs: 1_000_100 }));

  assert.equal(h.size, 2);
});

test("a cleared history does not swallow the next identical notification", () => {
  const h = history();
  h.add(incoming({ notifId: 1, arrivedMs: 1_000_000 }));
  h.clear();
  const result = h.add(incoming({ notifId: 2, arrivedMs: 1_000_100 }));

  assert.equal(result.duplicate, false);
  assert.equal(h.size, 1);
});

test("a duplicate from another app or sender is not collapsed", () => {
  const h = history();
  h.add(incoming({ notifId: 1, body: "ok", arrivedMs: 1_000_000 }));
  h.add(incoming({ notifId: 2, summary: "Bob", body: "ok", arrivedMs: 1_000_100 }));
  h.add(incoming({ notifId: 3, appName: "Slack", body: "ok", arrivedMs: 1_000_200 }));

  assert.equal(h.size, 3);
});

test("closing a notification drops every message that came from it", () => {
  const h = history();
  h.add(incoming({ notifId: 1, body: "a1", time: 1_000 }));
  h.add(incoming({ notifId: 1, body: "a2", time: 1_001 }));
  h.add(incoming({ notifId: 2, summary: "Bob", body: "b1", time: 1_002 }));

  assert.equal(h.removeNotification(1), true);
  assert.equal(h.removeNotification(1), false);
  assert.deepEqual(
    h.groups().map((g) => g.summary),
    ["Bob"],
  );
});

test("removing a group returns each notification it referenced once", () => {
  const h = history();
  h.add(incoming({ notifId: 1, body: "a1", time: 1_000 }));
  h.add(incoming({ notifId: 1, body: "a2", time: 1_001 }));
  h.add(incoming({ notifId: 3, body: "a3", time: 1_002 }));
  h.add(incoming({ notifId: 2, summary: "Bob", body: "b1", time: 1_003 }));

  const key = h.groups().find((g) => g.summary === "Alice")!.key;
  assert.deepEqual(h.removeGroup(key).sort(), [1, 3]);
  assert.deepEqual(h.removeGroup(key), []);
  assert.equal(h.size, 1);
});

test("clearing returns every referenced notification", () => {
  const h = history();
  h.add(incoming({ notifId: 1, body: "a1", time: 1_000 }));
  h.add(incoming({ notifId: 2, summary: "Bob", body: "b1", time: 1_001 }));

  assert.deepEqual(h.clear().sort(), [1, 2]);
  assert.equal(h.size, 0);
  assert.deepEqual(h.groups(), []);
});

test("pruning by age orphans only notifications nothing else references", () => {
  const h = new NotificationHistory({
    maxStored: 50,
    maxAgeSeconds: 100,
    duplicateWindowMs: 1_000,
  });
  h.add(incoming({ notifId: 1, body: "old", time: 1_000 }));
  h.add(incoming({ notifId: 1, body: "new", time: 1_150 }));
  h.add(incoming({ notifId: 2, summary: "Bob", body: "old", time: 1_000 }));

  assert.deepEqual(h.prune(1_200), [2]);
  assert.deepEqual(
    h.groups().flatMap((g) => g.messages.map((m) => m.body)),
    ["new"],
  );
});

test("the store keeps at most maxStored messages, dropping the oldest", () => {
  const h = new NotificationHistory({
    maxStored: 2,
    maxAgeSeconds: 3_600,
    duplicateWindowMs: 1_000,
  });
  h.add(incoming({ notifId: 1, body: "m1", time: 1_000 }));
  h.add(incoming({ notifId: 2, body: "m2", time: 1_001 }));
  const result = h.add(incoming({ notifId: 3, body: "m3", time: 1_002 }));

  assert.deepEqual(result.orphaned, [1]);
  assert.deepEqual(
    h.groups()[0].messages.map((m) => m.body),
    ["m3", "m2"],
  );
});

test("a group takes the most severe urgency among its messages", () => {
  const h = history();
  h.add(incoming({ notifId: 1, body: "a", urgency: "critical", time: 1_000 }));
  h.add(incoming({ notifId: 2, body: "b", urgency: "low", time: 1_001 }));

  assert.equal(h.groups()[0].urgency, "critical");
});
