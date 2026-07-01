# Provider Parity Protocol

Sister doc to `sync-details.md`. This file documents the per-provider
standardization pattern that the upstream Gentle AI toolkit uses, and the
rules this sync skill must enforce so that the same behavior is preserved
across every client (Claude, Codex, OpenCode, Generic) and across the
runtime-multiplexing pi-harness.

## 1. The standardization pattern (what upstream does)

Gentle AI ships a single behavioral contract (engram protocol, SDD
orchestrator rules, persona policy, command surface) and renders one
**variant per provider** under `internal/assets/<provider>/`. Variants
diverge only in:

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

Shared, provider-agnostic content lives in `internal/assets/skills/` and
is emitted as-is to every provider's `skills/` directory.

## 2. Asset matrix

Per-asset mapping. "shared" rows are provider-agnostic and should be
copied/mirrored verbatim into each client's tree.

| Asset kind                | Claude                              | Codex                                              | OpenCode                                                                       | Generic                            | Pi-harness                                                | Shared source                            |
| ------------------------- | ----------------------------------- | -------------------------------------------------- | ------------------------------------------------------------------------------ | ---------------------------------- | --------------------------------------------------------- | ---------------------------------------- |
| Engram protocol           | `claude/engram-protocol.md` AND inlined into `claude/sdd-orchestrator.md` | `codex/engram-instructions.md` (+ `engram-compact-prompt.md`) AND inlined into `codex/sdd-orchestrator.md` | injected into `opencode/AGENTS.md` AND inlined into `opencode/ORCHESTRATOR.md` | n/a (kept in persona/orchestrator) | inlined into `assets/orchestrator.md`                     | also inlined into shared `ORCHESTRATOR.md` |
| SDD orchestrator          | `claude/sdd-orchestrator.md`        | `codex/sdd-orchestrator.md`                        | `opencode/sdd-orchestrator.md` + `opencode/sdd-overlay-{single,multi}.json`    | `generic/sdd-orchestrator.md`      | embedded inside `assets/orchestrator.md`                  | --                                       |
| Persona / output style    | `claude/persona-gentleman.md` + `claude/output-style-gentleman.md` | implicit in `AGENTS.md`         | `opencode/persona-gentleman.md`                                                | `generic/persona-{gentleman,neutral}.md` | neutral by local policy (no persona file)            | --                                       |
| Global instructions       | `claude/CLAUDE.md` (composed)       | `codex/AGENTS.md` (composed)                       | `opencode/AGENTS.md` + JSON overlay                                            | shared `AGENTS.md`                 | `assets/orchestrator.md` (single file, provider-agnostic) | --                                       |
| Agents / sub-agents       | `claude/agents/*.md`                | none by default                                    | declared in `opencode/sdd-overlay-*.json` `agent` section                      | none                               | declared in pi-harness extension code                     | --                                       |
| Plugins / hooks           | n/a                                 | n/a                                                | `opencode/plugins/*.ts` (e.g. `model-variants.ts`, `background-agents.ts`)     | n/a                                | pi-harness extensions package                             | --                                       |
| Commands                  | `claude/commands/*.md`              | `codex/commands/*` if present                      | `opencode/commands/*.md`                                                       | shared `commands/`                 | pi-harness command registry                               | --                                       |
| Shared skills             | mirrored into `claude/skills/`      | mirrored into `codex/skills/`                      | mirrored into `opencode/skills/`                                               | mirrored into respective tree      | resolved from skill registry at runtime                   | `internal/assets/skills/` (and root `skills/`) |

### Orchestrator self-sufficiency rule (NON-NEGOTIABLE)

Every orchestrator file -- `ORCHESTRATOR.md` (shared), `claude/sdd-orchestrator.md`, `codex/sdd-orchestrator.md`, `opencode/ORCHESTRATOR.md`, and pi-harness `assets/orchestrator.md` -- MUST contain the full Engram protocol (PROACTIVE SAVE TRIGGERS, WHEN TO SEARCH MEMORY, SESSION CLOSE PROTOCOL, AFTER COMPACTION) inlined verbatim.

Never assume the orchestrator is co-loaded with `AGENTS.md` / `CLAUDE.md` / `engram-protocol.md` / `engram-instructions.md`. Some clients bind only the orchestrator file to the active agent slot; if engram lives only in the global instructions file, that client loses memory behavior.

The orchestrator is the orchestrator -- it must be self-sufficient at the agent layer.

Parity audit MUST verify, for each orchestrator file:

- Contains all four section headers: `PROACTIVE SAVE TRIGGERS`, `WHEN TO SEARCH MEMORY`, `SESSION CLOSE PROTOCOL`, `AFTER COMPACTION`.
- Codex variant additionally contains the `PASSIVE CAPTURE` / `Key Learnings` block.
- No persona/branding text introduced.
- Markdown dialect matches the provider conventions in section 5.

Quick check:

    grep -l 'PROACTIVE SAVE\|WHEN TO SEARCH\|SESSION CLOSE\|AFTER COMPACTION' \
      <orchestrator-files>

All four sections must be present in every file.

## 3. Behavior contract rule

When a behavior (a rule, trigger, search heuristic, save format, session
close requirement, after-compaction recovery step) is added or modified
in any provider variant, it MUST be reflected in every other variant
where the behavior applies. The sync skill enforces this by always
reviewing the **parallel file set** below for any single behavioral
change.

### Parallel file sets (review together)

Engram protocol changes -- inspect ALL of:

- `claude/engram-protocol.md`
- `codex/engram-instructions.md`
- `codex/engram-compact-prompt.md` (compaction prompt only)
- `opencode/AGENTS.md` (engram section)
- `opencode/sdd-overlay-{single,multi}.json` (if behavior affects overlay)
- Local mirror in `~/.tabularium/AI/claude/CLAUDE.md`
- Local mirror in `~/.tabularium/AI/codex/AGENTS.md`
- Local mirror in `~/.tabularium/AI/opencode/AGENTS.md`
- Pi-harness `~/dev/personal/pi-harness/assets/orchestrator.md` (union of all)

SDD orchestrator changes -- inspect ALL of:

- `claude/sdd-orchestrator.md`
- `codex/sdd-orchestrator.md`
- `opencode/sdd-orchestrator.md` + `opencode/sdd-overlay-*.json`
- `generic/sdd-orchestrator.md`
- Local `~/.tabularium/AI/{claude,codex}/sdd-orchestrator.md`
- Local `~/.tabularium/AI/opencode/ORCHESTRATOR.md`
- Pi-harness `assets/orchestrator.md` (SDD section)

Persona / branding -- inspect:

- `claude/persona-gentleman.md`, `claude/output-style-gentleman.md`
- `opencode/persona-gentleman.md`
- `generic/persona-{gentleman,neutral}.md`
- Local Tabularium neutralization policy (drop branding in local outputs)

Commands -- per-provider command dirs plus shared `commands/`.

## 4. Pi-harness special role

Pi-harness is the runtime client: it embeds the AI loop and switches
between providers (Claude, Codex/GPT-5.5, etc.) internally. There is no
per-provider asset split inside pi-harness. Its single
`assets/orchestrator.md` is injected verbatim into the system prompt
regardless of which provider is currently active.

Consequence: pi-harness `assets/orchestrator.md` MUST contain the
**union** of provider-independent behaviors. When the engram protocol or
SDD orchestrator gains a rule in any provider variant, pi-harness
orchestrator.md must receive the same update so behavior remains
consistent across pi sessions regardless of the active provider.

Concrete trigger that motivated this rule: pi running under GPT-5.5
(openai-codex provider) skipped engram on the user's first message
because the proactive-search rule lived only in Claude-side
`CLAUDE.md`. The fix was to inline the full engram protocol into
`pi-harness/assets/orchestrator.md` (commit 54fbef1). Any future
behavioral addition must follow the same pattern.

Sync action: this skill does NOT write into the pi-harness repo
directly (out of policy scope), but it MUST flag in its output report
any behavioral change that requires a pi-harness orchestrator.md
update, so the user can apply it in that repo.

## 5. Provider-specific adaptation rules

When propagating a behavior across variants, translate per these
conventions discovered by comparing upstream `claude/engram-protocol.md`
against `codex/engram-instructions.md` and `opencode/sdd-orchestrator.md`:

### Markdown formatting

| Concern              | Claude variant                                | Codex variant                                | OpenCode variant                             | Pi-harness (union)                     |
| -------------------- | --------------------------------------------- | -------------------------------------------- | -------------------------------------------- | -------------------------------------- |
| Bold/emphasis        | `**bold**` allowed and used                   | `**bold**` allowed but minimized             | `**bold**` allowed; sometimes plain ASCII    | follow Claude (richest renderer)       |
| Code fences for tool names | backticks around `mem_save`, `mem_search`  | backticks optional; plain `mem_save` accepted | backticks; tool names match OpenCode tools (`delegate`, `task`) | backticks always |
| Arrows               | unicode `→`                                   | unicode `→` accepted                         | ASCII `->`                                   | ASCII `->` (safest cross-provider)     |
| HTML comment fences  | `<!-- gentle-ai:section -->` for merge anchors | not used                                     | not used                                     | not used                               |
| Emoji in tables (`✅`) | allowed                                       | allowed                                      | avoid; use plain `Yes`/`--`                  | avoid                                  |

### Tool surface

| Behavior          | Claude                       | Codex                  | OpenCode                                 |
| ----------------- | ---------------------------- | ---------------------- | ---------------------------------------- |
| Sub-agent launch  | "Agent tool call"            | "sub-agent" (generic)  | `delegate` (async) / `task` (sync) tools |
| Passive learning  | not supported -- omit "Key Learnings" auto-capture | `mem_capture_passive` + "## Key Learnings:" auto-extraction | not supported by default |
| Compaction prompt | implicit via Claude UI       | explicit `engram-compact-prompt.md` ships separately | implicit                       |

### Loader mechanism

| Provider  | How instructions reach the model                                                |
| --------- | ------------------------------------------------------------------------------- |
| Claude    | `~/.claude/CLAUDE.md` global + per-project; skills auto-discovered              |
| Codex     | `AGENTS.md` at workspace root; engram-compact-prompt fed to compaction step     |
| OpenCode  | `AGENTS.md` + JSON overlay (`sdd-overlay-*.json`) declares agents and tools     |
| Pi-harness | single `assets/orchestrator.md` injected into system prompt by the harness     |

When OpenCode is the target, behavior added to `AGENTS.md` may also
require updating the JSON overlay if it touches agent definitions, tool
permissions, or sub-agent prompt files. Always inspect both.

## 6. Sync workflow addendum

After applying upstream updates (step 7 in SKILL.md):

1. Identify which behavioral surfaces changed (engram, SDD orchestrator,
   persona, commands).
2. For each changed surface, walk the parallel file set in section 3
   and confirm the change is present in every relevant file. Where
   upstream is the source of truth, propagate; where local policy
   differs (e.g. neutralization), preserve local policy but verify the
   behavior is present.
3. If pi-harness orchestrator.md is affected, do NOT edit it; emit an
   explicit "pi-harness update required" line in the sync report with
   the exact paragraph(s) to add.
4. Report any gaps where a behavior exists in one provider but not
   another so the user can decide priority.

## 7. Why this skill is mirrored to client trees

Per the parity rule itself, `upstream-ai-sync` is now mirrored to
`{claude,codex,opencode}/skills/upstream-ai-sync/` so that any client
session can run a parity audit and propose updates. The canonical copy
remains under `~/.tabularium/AI/skills/upstream-ai-sync/`; mirrors are
synchronized copies.
