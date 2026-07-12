---
name: upstream-ai-sync
description: "Trigger: update skills, commands, agents, orchestrator assets. Sync upstream AI into the @ai canonical tree while preserving local policy."
license: Apache-2.0
metadata:
  author: iperez
  version: "3.0"
---

## Activation Contract

Load this skill when updating local skills, commands, agents, SDD prompts, AGENTS files, or orchestrator assets from upstream AI toolkits into the canonical Home Manager tree at `/home/iperez/.config/home-manager/ai/` (referred to as `@ai`).

Two upstream sources participate:

- `~/.cache/tabularium-ai/upstream-ai-toolkit/` — gentle-ai (multi-client meta-toolkit; per-client assets under `internal/assets/{claude,codex,opencode,generic,skills,gga,gemini,antigravity,windsurf,cursor,kimi,qwen,kiro,hermes}`).
- `~/.cache/tabularium-ai/gentle-pi/` — gentle-pi (Pi-specific npm package; assets under `assets/{agents,chains,support,orchestrator.md}`, `extensions/`, `prompts/`, `skills/`).

## Canonical Source vs Runtime — Read First

**`@ai` (`/home/iperez/.config/home-manager/ai/`) is the single source of truth.** It is git-tracked inside the Home Manager repository. Every sync write lands here and nowhere else.

**The old `~/.tabularium/AI` hub is dead.** That path is now only Obsidian notes (`NOTES_DIR`), not a harness hub. Never sync harness assets into it and never treat it as a client tree.

**Runtime install is by Nix projection, NOT by this skill.** Home Manager (`home-manager/global/ai-harness.nix`) is the authoritative projection map: it symlinks each `ai/<...>` source to its runtime location from `/nix/store`, or renders secret templates at activation. This skill edits `@ai` sources only; `home-manager switch` deploys them.

Hard consequence — **never write into runtime dirs** (`~/.claude`, `~/.config/opencode`, `~/.codex`, `~/.agents`, `~/.pi/agent`). They are Nix-managed (read-only store symlinks or activation-rendered files). Edits there either fail or are clobbered on the next `home-manager switch`. A projection preflight also aborts `switch` if a projection target is an unmanaged file/symlink, so never create stray files at any target path.

### Projected resources (source under `ai/` -> runtime target)

Taken verbatim from `ai-harness.nix` `projectedResources`:

| Source under `ai/` | Runtime target |
|---|---|
| `skills` | `.agents/skills` (shared/canonical skills) |
| `opencode/AGENTS.md` | `.config/opencode/AGENTS.md` |
| `opencode/ORCHESTRATOR.md` | `.config/opencode/ORCHESTRATOR.md` |
| `opencode/agent` | `.config/opencode/agent` |
| `opencode/commands` | `.config/opencode/commands` |
| `command` | `.config/opencode/command` |
| `opencode/prompts` | `.config/opencode/prompts` |
| `opencode/skills` | `.config/opencode/skills` |
| `opencode/tui.json` | `.config/opencode/tui.json` |
| `claude/CLAUDE.md` | `.claude/CLAUDE.md` |
| `claude/sdd-orchestrator.md` | `.claude/sdd-orchestrator.md` |
| `claude/engram-protocol.md` | `.claude/engram-protocol.md` |
| `claude/agents` | `.claude/agents` |
| `claude/commands` | `.claude/commands` |
| `claude/skills` | `.claude/skills` |
| `codex/AGENTS.md` | `.codex/AGENTS.md` |
| `codex/sdd-orchestrator.md` | `.codex/sdd-orchestrator.md` |
| `codex/engram-instructions.md` | `.codex/engram-instructions.md` |
| `codex/engram-compact-prompt.md` | `.codex/engram-compact-prompt.md` |
| `codex/commands` | `.codex/commands` |
| `codex/agents` | `.codex/agents` |
| `codex/skills` | `.codex/skills` |

### Secret-bearing configs (NEVER hold real tokens)

These carry `@VAR@` placeholders and are rendered or merged at activation from the secret env files. Preserve the placeholder form; never expand or commit a secret value.

- Rendered whole-file: `opencode/opencode.jsonc` -> `.config/opencode/opencode.jsonc`; `pi/mcp.json` -> `.pi/agent/mcp.json`.
- Merged (MCP/section-only into an agent-owned file): `claude/mcp-servers.json` -> `.claude.json`; `codex/mcp-servers.toml` -> `.codex/config.toml`; `claude/settings-merge.json` -> `.claude/settings.json`.

### Managed provider subset

`@ai` mirrors only **claude, codex, opencode**, plus the shared `ai/skills` and `ai/command`, plus `ai/pi/mcp.json` (secret template only). Upstream gentle-ai ships many more providers (claude, opencode, codex, generic, gemini, cursor, kimi, kiro, qwen, windsurf, antigravity, gga, hermes, skills — the current `//go:embed` roots in `internal/assets/assets.go`). Map upstream onto the user subset only:

| Upstream | User target |
|---|---|
| `claude` | `ai/claude` |
| `codex` | `ai/codex` |
| `opencode` | `ai/opencode` |
| `skills` (and root `skills/`) | `ai/skills` and per-client mirrors `ai/{claude,codex,opencode}/skills` |
| `generic` / shared-agnostic behavior | `ai/shared` authoring layer |

The other upstream providers (`gemini`, `cursor`, `kimi`, `kiro`, `qwen`, `windsurf`, `antigravity`, `gga`, `hermes`) are intentionally NOT managed. Do not create them.

### `ai/shared/` is an authoring layer, not projected

Only the per-client files in the projection table are deployed. `ai/shared/ORCHESTRATOR.md`, `ai/shared/AGENTS.md`, and `ai/shared/engram-protocol.md` are the canonical behavioral contract that the per-client copies (`ai/opencode/ORCHESTRATOR.md`, `ai/claude/sdd-orchestrator.md`, `ai/codex/sdd-orchestrator.md`, and the rendered engram files) MUST stay in parity with. Nothing auto-generates the per-client copies from shared; parity is enforced by keeping them aligned by hand.

### Pi boundary

`~/dev/personal/pi-harness` and `~/.pi/agent` remain valid Pi targets, handled separately. Pi's runtime comes from the external pi-harness flake input, not from `@ai`. The only Pi asset that lives in `@ai` is `ai/pi/mcp.json` (a secret template projected to `.pi/agent/mcp.json`). Keep Pi handling, but do not fold pi-harness assets into the `@ai` projection.

## Core Principle — 1:1 + Customization Layer

Upstream is the source of truth for structure, asset surface, and content. Local customizations layer on top. Order of operations: **mirror upstream -> strip persona/branding -> re-apply known user customizations**. Never silently drop an upstream asset; never silently overwrite a user customization.

### Stripped from upstream during sync

- "Gentleman" persona text, `persona-gentleman.md`, `output-style-gentleman.md`, persona-mode switching prompts.
- Branding strings: `el Gentleman`, `gentleman-programming`, `@Gentleman-Programming`, `Gentle AI`, `gentle-orchestrator`. Replace identifiers with neutral equivalents (`sdd-orchestrator`, `iperez`, etc.). Keep `gentle-ai`/`gentle-pi` only when referring to the upstream toolkit by name in documentation.
- Startup banner branding text in gentle-pi's `extensions/startup-banner.ts` (keep any functional behavior; remove only the branded text).

### Preserved as user customizations (layer back on after upstream copy)

| Customization | Where it applies |
|---|---|
| `.agents/` paths instead of `.atl/` | every `skill-registry`, `sdd-init`, and orchestrator reference |
| Obsidian as 5th `artifact_store.mode` | `sdd-init`, orchestrator, `skills/_shared/persistence-contract.md`, `skills/_shared/obsidian-convention.md` |
| Pi model assignments (`openai-codex/gpt-5.4` for SDD agents, etc.) | pi-harness `assets/agents/*.md` frontmatter |
| Engram + Obsidian as default persistence, no `openspec/` in repos | `skills/_shared/persistence-contract.md`, orchestrator artifact-store text |
| Inlined Engram protocol in per-client orchestrators | `claude/sdd-orchestrator.md`, `codex/sdd-orchestrator.md`, `opencode/ORCHESTRATOR.md`, pi-harness `assets/orchestrator.md` |
| User-authored skills not present upstream: `obsidian`, `dbflux-release`, `find-skills`, `upstream-ai-sync` | canonical `ai/skills` + every client mirror |
| User-authored agents: `bug-hunter`, `pr-reviewer` (claude/opencode) | `claude/agents/`, `opencode/agent/` |
| `author: iperez` in skill frontmatter | every skill SKILL.md |

## Current gentle-ai (v2.0) awareness — runtime-only caveat

Current gentle-ai (v2.0) introduced a **runtime-backed review/delegation lifecycle** enforced by the gentle-ai Go binary: bounded review transactions (`internal/components/reviewtransaction`), receipts/CAS, a frozen-ledger validation lifecycle, and native OpenCode `general`/`explore` agent routing. These CANNOT be reproduced by prompt assets alone.

Rule: when syncing behavior from these areas, port only the prompt-expressible portion into `@ai`'s prompt/orchestrator assets, and explicitly document the runtime-only remainder as not-reproducible instead of faking it with sub-agent gymnastics. This prevents the harness from inheriting gate rules it cannot actually execute.

## Hard Rules

- Work only in `/home/iperez/.config/home-manager/ai` (`@ai`), the pi-harness repo, and the upstream caches under `/home/iperez/.cache/tabularium-ai/`, unless the user names another target.
- Never write into runtime dirs (`~/.claude`, `~/.config/opencode`, `~/.codex`, `~/.agents`, `~/.pi/agent`). They are Nix-managed. Edit `@ai` sources; `home-manager switch` deploys them.
- Never create a stray file at any projection target path; the projection preflight aborts `switch` on unmanaged targets.
- Do not run `home-manager` or any mutating deployment command as part of this skill unless the user explicitly asks.
- Do not modify either upstream checkout except `git clone`, `git fetch`, `git pull --ff-only`, or read-only inspection.
- Snapshot before writing, OUTSIDE the nix git repo: copy current state of every target directory to `~/.cache/tabularium-ai/sync-snapshots/YYYYMMDD-HHMMSS/` before any modification. Never snapshot into `@ai`; that would pollute the git-tracked config.
- For secret-bearing configs, preserve `@VAR@` placeholder form; never expand or commit a real secret value.
- For PRESENT_DRIFT files: classify the drift before acting. If drift is in the "preserved customizations" table above, KEEP local. If drift is in a section the user has not touched (visible from snapshot history) and upstream changed, ADOPT upstream content while re-applying preserved customizations. If drift is ambiguous, ASK the user.
- For MISSING_IN_USER files: only when the asset maps into the managed subset (claude/codex/opencode/shared skills/command). Copy from upstream, strip persona, apply customizations, write to the `@ai` source. Mirror to each relevant client tree. Do NOT create providers outside the managed subset.
- For USER_ONLY files: if listed in "preserved customizations", KEEP. Otherwise flag for user decision; do not auto-delete.
- Sync whole skill packages, not only `SKILL.md`; preserve every file under the skill directory, including `assets/`, `references/`, and direct companion files (strict-TDD guides, etc.).
- Before syncing skills, inspect upstream `docs/skill-style-guide.md` if present and preserve new frontmatter fields such as `disable-model-invocation` and `user-invocable`.
- Resulting instruction assets must use neutral personality and remove visible branding/persona references unless the identifier is technically required.
- Obsidian and Engram are always the planning/spec persistence backends; do not write OpenSpec artifacts into a normal repo tree unless explicitly requested.
- An orchestrator must never delegate to another orchestrator; prefer non-blocking sub-agent delegation.
- Do not sync generated validation fixtures, local runtime state, user backups, auth files, caches, or project planning artifacts unless the user explicitly asks for that exact target.
- Do not sync the pi-harness Engram extension surface from gentle-pi; engram is handled separately. Touching `pi-harness/extensions/` requires explicit user instruction.
- Enforce provider parity: when upstream changes a behavior (engram protocol, SDD orchestrator rule, persona/branding contract), inspect every parallel file listed in `references/provider-parity.md` so the same behavior is present in all managed provider copies and reported for the pi-harness orchestrator.

## Provider Parity Protocol

The upstream toolkit ships one behavioral contract rendered as per-provider variants. `@ai` keeps a per-client copy for claude, codex, and opencode, with `ai/shared/` as the canonical contract. The sync skill MUST keep the managed variants in lockstep when a behavior changes, and MUST flag pi-harness `assets/orchestrator.md` updates (pi-harness is not in this skill's write scope, but its orchestrator is the runtime union of all provider variants). See `references/provider-parity.md` for the asset matrix, parallel file sets, per-provider formatting rules, and the pi-harness handling rule.

## Decision Gates

| Situation | Action |
|---|---|
| MISSING_IN_USER, maps into managed subset | Copy upstream -> strip persona -> apply preserved customizations -> write to `@ai` source and every relevant client mirror. |
| MISSING_IN_USER, outside managed subset | Do NOT create; note as intentionally unmanaged. |
| PRESENT_1to1 (byte-identical) | No action. |
| PRESENT_DRIFT, drift matches preserved-customization table | KEEP local. |
| PRESENT_DRIFT, upstream-only changes in untouched sections | RESYNC content from upstream; re-apply preserved customizations. |
| PRESENT_DRIFT, both changed same section | ASK before writing unless purely mechanical (whitespace, em-dash normalization). |
| USER_ONLY in preserved-customization table | KEEP. |
| USER_ONLY not in table | FLAG for user decision; do not auto-delete. |
| Branding/persona content in upstream | STRIP during sync; never propagate to user files. |
| Persistence conflict | Obsidian + Engram wins. |
| Runtime-only behavior (v2.0 review/ledger/CAS/native agent routing) | Port prompt-expressible portion only; document the runtime remainder as not-reproducible. |

## Execution Steps

1. Prepare/update both upstream caches; record commit SHAs for `upstream-ai-toolkit` and `gentle-pi`.
2. Snapshot every target tree under `~/.cache/tabularium-ai/sync-snapshots/YYYYMMDD-HHMMSS/` BEFORE any write. Never snapshot into `@ai`.
3. Inspect `internal/assets/assets.go` in gentle-ai to discover currently embedded asset roots. Inspect `assets/`, `extensions/`, `prompts/`, `skills/` in gentle-pi to discover its surface.
4. Map each relevant upstream asset onto the managed `@ai` subset (claude/codex/opencode/shared skills/command). Ignore providers outside the subset.
5. Inventory upstream surfaces:
   - gentle-ai: `internal/assets/skills/**`, root `skills/**`, `docs/skill-style-guide.md`, `docs/agents.md`, and the `claude`/`codex`/`opencode`/`generic` per-client assets.
   - gentle-pi: `assets/agents/**`, `assets/chains/**`, `assets/support/**`, `assets/orchestrator.md`, `extensions/**`, `prompts/**`, `skills/**`.
6. Compare against the local `@ai` sources: `ai/{claude,codex,opencode}/`, `ai/skills/`, `ai/command/`, `ai/shared/`, and `ai/pi/mcp.json`; plus pi-harness `assets/` handled separately.
7. For each file, classify as PRESENT_1to1 / PRESENT_DRIFT / MISSING_IN_USER / USER_ONLY and apply the Decision Gates table.
8. After applying upstream updates, verify behavior changes are reflected across ALL managed provider files per `references/provider-parity.md`. Walk each parallel file set for the changed surface (engram, SDD orchestrator, persona, commands), including `ai/shared/` as the canonical contract. Where pi-harness `assets/orchestrator.md` would need an update, emit an explicit "pi-harness update required" line with the exact paragraph(s) to add.
9. For any behavior originating in v2.0 runtime areas (review transactions, receipts/CAS, frozen-ledger validation, native `general`/`explore` routing), port only the prompt-expressible portion and record the runtime-only remainder as not-reproducible.
10. Validate skill frontmatter against upstream tests, recursive skill package copying, branding policy, neutral policy, Obsidian+Engram policy, no orchestrator-to-orchestrator delegation, non-blocking delegation preference, and `@VAR@` placeholder integrity.
11. Final validation: grep `@ai` (and, if in scope, pi-harness) for residual persona/branding strings (target: zero hits). Grep for `.atl/skill-registry` (target: zero hits). Confirm no real secret values leaked into secret-bearing configs. Confirm preserved customizations are intact.

## Output Contract

Return upstream cache path and commit, compared counts for skills/references/commands/agents/orchestrators, updated `@ai` source files, kept-local files, conflicts requiring decision, any runtime-only behavior noted as not-reproducible, and validation results. Remind the user that changes take effect only after `home-manager switch`.

## References

- `references/sync-details.md` — canonical `@ai` paths, projection targets, upstream locations, secret-config rules, snapshot location, merge rules, and report template.
- `references/provider-parity.md` — per-provider standardization pattern, asset matrix for the managed subset, behavior contract rule, parallel file sets, pi-harness handling, and provider-specific adaptation rules (markdown dialect, tool surface, loader mechanism).
