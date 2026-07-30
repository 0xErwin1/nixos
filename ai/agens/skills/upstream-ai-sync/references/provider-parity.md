# Provider Parity Protocol

Sister doc to `sync-details.md`. This file documents the per-provider
standardization pattern that the upstream gentle-ai toolkit uses, and the
rules this sync skill must enforce so that the same behavior is preserved
across every **managed** client (Claude, Codex, OpenCode) and reported for
the runtime-multiplexing pi-harness.

Scope note: `@ai` manages only claude, codex, and opencode, with
`ai/shared/` as the canonical contract. Upstream ships more provider
variants; this doc concerns only the managed subset plus pi-harness.

## 1. The standardization pattern (what upstream does)

gentle-ai ships a single behavioral contract (engram protocol, SDD
orchestrator rules, persona policy, command surface) and renders one
variant per provider under `internal/assets/<provider>/`. Variants diverge
only in:

- Markdown dialect supported by the host (Claude renders bold/emoji/HTML
  comment markers; Codex prefers plain ASCII; OpenCode embeds JSON
  manifests with `{file:./AGENTS.md}` references).
- Tool/feature surface (e.g. `delegate` vs `task` tool names in OpenCode;
  passive-capture "Key Learnings" works in Codex but not Claude; HTML
  comment fences `<!-- gentle-ai:sdd-model-assignments -->` exist only in
  the Claude variant for selective merging).
- Loader mechanism (Claude reads `CLAUDE.md` + skill files directly;
  Codex reads `AGENTS.md` + `engram-compact-prompt.md`; OpenCode reads a
  JSON overlay that wires `agent` definitions and plugins).

The **behavior** (when to save to engram, when to search, what to write
at session close, how the orchestrator delegates) is identical. The
**shape** is provider-tuned.

In `@ai`, the canonical contract lives in `ai/shared/`
(`ORCHESTRATOR.md`, `AGENTS.md`, `engram-protocol.md`). Nothing
auto-generates the per-client copies from it; parity is enforced by
keeping the managed copies aligned with `ai/shared/` by hand.

## 2. Asset matrix (managed subset)

Per-asset mapping across the managed clients. `ai/shared/` is the
canonical source; it is NOT projected to runtime.

| Asset kind | Canonical (`ai/shared/`) | Claude (`ai/claude/`) | Codex (`ai/codex/`) | OpenCode (`ai/opencode/`) | Pi-harness (out of write scope) |
|---|---|---|---|---|---|
| Engram protocol | `engram-protocol.md` | `engram-protocol.md` AND inlined into `sdd-orchestrator.md` | `engram-instructions.md` + `engram-compact-prompt.md` AND inlined into `sdd-orchestrator.md` | injected into `AGENTS.md` AND inlined into `ORCHESTRATOR.md` | inlined into `assets/orchestrator.md` |
| SDD orchestrator | `ORCHESTRATOR.md` | `sdd-orchestrator.md` | `sdd-orchestrator.md` | `ORCHESTRATOR.md` + `sdd-overlay-{single,multi}.json` | embedded in `assets/orchestrator.md` |
| Global instructions | `AGENTS.md` | `CLAUDE.md` | `AGENTS.md` | `AGENTS.md` + JSON overlay | `assets/orchestrator.md` |
| Persona / output style | neutral by local policy | stripped (no persona file) | implicit in `AGENTS.md` | stripped (no persona file) | neutral by local policy |
| Agents / sub-agents | -- | `agents/*.md` | `agents/*.md` | `agent/*.md` + overlay `agent` section | declared in pi-harness extension code |
| Commands | -- | `commands/*.md` | `commands/*` | `commands/*.md` (+ shared `ai/command/`) | pi-harness command registry |
| Shared skills | `ai/skills/` (canonical) | mirrored into `claude/skills/` | mirrored into `codex/skills/` | mirrored into `opencode/skills/` | resolved from skill registry at runtime |

### Orchestrator self-sufficiency rule (NON-NEGOTIABLE)

Every orchestrator file -- `ai/shared/ORCHESTRATOR.md` (canonical),
`ai/claude/sdd-orchestrator.md`, `ai/codex/sdd-orchestrator.md`,
`ai/opencode/ORCHESTRATOR.md`, and pi-harness `assets/orchestrator.md`
-- MUST contain the full Engram protocol (PROACTIVE SAVE TRIGGERS, WHEN
TO SEARCH MEMORY, SESSION CLOSE PROTOCOL, AFTER COMPACTION) inlined
verbatim.

Never assume the orchestrator is co-loaded with `AGENTS.md` /
`CLAUDE.md` / `engram-protocol.md` / `engram-instructions.md`. Some
clients bind only the orchestrator file to the active agent slot; if
engram lives only in the global instructions file, that client loses
memory behavior.

The orchestrator is the orchestrator -- it must be self-sufficient at
the agent layer.

Parity audit MUST verify, for each orchestrator file:

- Contains all four section headers: `PROACTIVE SAVE TRIGGERS`, `WHEN TO
  SEARCH MEMORY`, `SESSION CLOSE PROTOCOL`, `AFTER COMPACTION`.
- Codex variant additionally contains the `PASSIVE CAPTURE` / `Key
  Learnings` block.
- No persona/branding text introduced.
- Markdown dialect matches the provider conventions in section 5.

Quick check:

    grep -l 'PROACTIVE SAVE\|WHEN TO SEARCH\|SESSION CLOSE\|AFTER COMPACTION' \
      ai/shared/ORCHESTRATOR.md \
      ai/claude/sdd-orchestrator.md \
      ai/codex/sdd-orchestrator.md \
      ai/opencode/ORCHESTRATOR.md

All four sections must be present in every file.

## 3. Behavior contract rule

When a behavior (a rule, trigger, search heuristic, save format, session
close requirement, after-compaction recovery step) is added or modified
in any provider variant, it MUST be reflected in every managed variant
where the behavior applies, and in `ai/shared/` as the canonical record.
The sync skill enforces this by always reviewing the **parallel file
set** below for any single behavioral change.

### Parallel file sets (review together)

Engram protocol changes -- inspect ALL of:

- `ai/shared/engram-protocol.md` (canonical sectioned source)
- `ai/claude/engram-protocol.md` (rendered `full` section)
- `ai/claude/CLAUDE.md` (engram section)
- `ai/claude/sdd-orchestrator.md` (inlined)
- `ai/codex/engram-instructions.md` (rendered `full` + `passive-capture`)
- `ai/codex/engram-compact-prompt.md` (rendered `compact` section)
- `ai/codex/AGENTS.md` (engram section)
- `ai/codex/sdd-orchestrator.md` (inlined)
- `ai/opencode/AGENTS.md` (engram section)
- `ai/opencode/ORCHESTRATOR.md` (inlined)
- `ai/opencode/sdd-overlay-{single,multi}.json` (if behavior affects overlay)
- pi-harness `assets/orchestrator.md` (union of all; out of write scope, flag only)

SDD orchestrator changes -- inspect ALL of:

- `ai/shared/ORCHESTRATOR.md`
- `ai/claude/sdd-orchestrator.md`
- `ai/codex/sdd-orchestrator.md`
- `ai/opencode/ORCHESTRATOR.md` + `ai/opencode/sdd-overlay-*.json`
- pi-harness `assets/orchestrator.md` (SDD section; flag only)

Persona / branding -- inspect and neutralize:

- Any upstream `persona-*` / `output-style-*` source
- `ai/shared/`, `ai/claude/`, `ai/codex/`, `ai/opencode/` synced outputs
- Local neutralization policy (drop branding in all local outputs)

Commands -- per-provider command dirs (`ai/{claude,codex,opencode}/commands/`)
plus the shared `ai/command/`.

## 4. Pi-harness special role

Pi-harness is the runtime client: it embeds the AI loop and switches
between providers (Claude, Codex/GPT, etc.) internally. There is no
per-provider asset split inside pi-harness. Its single
`assets/orchestrator.md` is injected verbatim into the system prompt
regardless of which provider is currently active. Its runtime comes from
the external pi-harness flake input, not from `@ai`; the only Pi asset in
`@ai` is `ai/pi/mcp.json`.

Consequence: pi-harness `assets/orchestrator.md` MUST contain the
**union** of provider-independent behaviors. When the engram protocol or
SDD orchestrator gains a rule in any managed variant, pi-harness
orchestrator.md must receive the same update so behavior stays consistent
across pi sessions regardless of the active provider.

Concrete trigger that motivated this rule: pi running under a
codex-provider model skipped engram on the user's first message because
the proactive-search rule lived only in Claude-side instructions. The fix
was to inline the full engram protocol into
`pi-harness/assets/orchestrator.md`. Any future behavioral addition must
follow the same pattern.

Sync action: this skill does NOT write into the pi-harness repo (out of
policy scope), but it MUST flag in its output report any behavioral
change that requires a pi-harness orchestrator.md update, so the user can
apply it in that repo.

## 5. Provider-specific adaptation rules

When propagating a behavior across variants, translate per these
conventions discovered by comparing upstream `claude/engram-protocol.md`
against `codex/engram-instructions.md` and `opencode/sdd-orchestrator.md`:

### Markdown formatting

| Concern | Claude variant | Codex variant | OpenCode variant | Pi-harness (union) |
|---|---|---|---|---|
| Bold/emphasis | `**bold**` allowed and used | `**bold**` allowed but minimized | `**bold**` allowed; sometimes plain ASCII | follow Claude (richest renderer) |
| Code fences for tool names | backticks around `mem_save`, `mem_search` | backticks optional; plain `mem_save` accepted | backticks; tool names match OpenCode tools (`delegate`, `task`) | backticks always |
| Arrows | unicode `→` | unicode `→` accepted | ASCII `->` | ASCII `->` (safest cross-provider) |
| HTML comment fences | `<!-- gentle-ai:section -->` for merge anchors | not used | not used | not used |
| Emoji in tables | allowed | allowed | avoid; use plain `Yes`/`--` | avoid |

### Tool surface

| Behavior | Claude | Codex | OpenCode |
|---|---|---|---|
| Sub-agent launch | "Agent tool call" | "sub-agent" (generic) | `delegate` (async) / `task` (sync) tools |
| Passive learning | not supported -- omit "Key Learnings" auto-capture | `mem_capture_passive` + "## Key Learnings:" auto-extraction | not supported by default |
| Compaction prompt | implicit via Claude UI | explicit `engram-compact-prompt.md` ships separately | implicit |

### Loader mechanism

| Provider | How instructions reach the model |
|---|---|
| Claude | `~/.claude/CLAUDE.md` global + per-project; skills auto-discovered (projected from `ai/claude/`) |
| Codex | `AGENTS.md` at workspace root; engram-compact-prompt fed to compaction step (projected from `ai/codex/`) |
| OpenCode | `AGENTS.md` + JSON overlay (`sdd-overlay-*.json`) declares agents and tools (projected from `ai/opencode/`) |
| Pi-harness | single `assets/orchestrator.md` injected into system prompt by the harness (external flake input) |

When OpenCode is the target, behavior added to `AGENTS.md` may also
require updating the JSON overlay if it touches agent definitions, tool
permissions, or sub-agent prompt files. Always inspect both.

## 6. Runtime-only behaviors (v2.0) — not reproducible by parity

Current gentle-ai (v2.0) enforces a review/delegation lifecycle in the Go
binary: bounded review transactions (`internal/components/reviewtransaction`),
receipts/CAS, a frozen-ledger validation lifecycle, and native OpenCode
`general`/`explore` agent routing. These are NOT prompt assets and cannot
be reproduced by keeping provider files in parity.

When a behavioral change originates in these areas, port only the
prompt-expressible portion into the managed provider assets and record
the runtime-only remainder as not-reproducible in the sync report. Do not
attempt to emulate a runtime gate with sub-agent gymnastics; that would
make the harness advertise a gate it cannot execute.

## 7. Sync workflow addendum

After applying upstream updates (step 8 in SKILL.md):

1. Identify which behavioral surfaces changed (engram, SDD orchestrator,
   persona, commands).
2. For each changed surface, walk the parallel file set in section 3 and
   confirm the change is present in every managed file and recorded in
   `ai/shared/`. Where upstream is the source of truth, propagate; where
   local policy differs (e.g. neutralization), preserve local policy but
   verify the behavior is present.
3. If the change originates in a v2.0 runtime area (section 6), port only
   the prompt-expressible portion and document the remainder as
   not-reproducible.
4. If pi-harness orchestrator.md is affected, do NOT edit it; emit an
   explicit "pi-harness update required" line in the sync report with the
   exact paragraph(s) to add.
5. Report any gaps where a behavior exists in one provider but not another
   so the user can decide priority.

## 8. Why this skill is mirrored to client trees

Per the parity rule itself, `upstream-ai-sync` is mirrored to
`ai/{claude,codex,opencode}/skills/upstream-ai-sync/` so that any managed
client session can run a parity audit and propose updates. The canonical
copy lives under `ai/skills/upstream-ai-sync/`; the client copies are
synchronized mirrors and are propagated from the canonical copy, not
edited directly.
