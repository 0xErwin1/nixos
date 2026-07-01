---
name: upstream-ai-sync
description: "Trigger: update skills, commands, agents, orchestrator assets. Sync upstream AI assets into Tabularium while preserving local policy."
license: Apache-2.0
metadata:
  author: iperez
  version: "2.0"
---

## Activation Contract

Load this skill when updating local skills, commands, agents, SDD prompts, AGENTS files, or orchestrator assets from upstream AI toolkits (`gentle-ai` for multi-client, `gentle-pi` for Pi runtime) into `/home/iperez/.tabularium/AI`, `/home/iperez/dev/personal/pi-harness/assets`, and `/home/iperez/.pi/agent`.

Two upstream sources participate:

- `~/.cache/tabularium-ai/upstream-ai-toolkit/` — gentle-ai (multi-client meta-toolkit; per-client assets under `internal/assets/{claude,codex,opencode,generic,cursor,kimi,kiro,gemini,qwen,antigravity,windsurf,gga,...}`).
- `~/.cache/tabularium-ai/gentle-pi/` — gentle-pi (Pi-specific npm package; assets under `assets/{agents,chains,support,orchestrator.md}`, `extensions/`, `prompts/`, `skills/`).

## Core Principle — 1:1 + Customization Layer

Upstream is the source of truth for structure, asset surface, and content. Local customizations layer on top. Order of operations: **mirror upstream -> strip persona/branding -> re-apply known user customizations**. Never silently drop an upstream asset; never silently overwrite a user customization.

### Stripped from upstream during sync

- "Gentleman" persona text, `persona-gentleman.md`, `output-style-gentleman.md`, persona-mode switching prompts.
- Branding strings: `el Gentleman`, `gentleman-programming`, `@Gentleman-Programming`, `Gentle AI`, `gentle-orchestrator`. Replace identifiers with neutral equivalents (`sdd-orchestrator`, `iperez`, etc.). Keep `gentle-ai`/`gentle-pi` only when referring to the upstream toolkit by name in documentation.
- Startup banner branding text in gentle-pi's `extensions/startup-banner.ts` (keep any functional behavior; remove only the branded text).

### Preserved as user customizations (layer back on after upstream copy)

| Customization | Where it applies |
|---|---|
| `.agent/` paths instead of `.atl/` | every `skill-registry`, `sdd-init`, and orchestrator reference |
| Obsidian as 5th `artifact_store.mode` | `sdd-init`, orchestrator, `_shared/persistence-contract.md`, `_shared/obsidian-convention.md` |
| Pi model assignments (`openai-codex/gpt-5.4` for SDD agents, etc.) | pi-harness `assets/agents/*.md` frontmatter |
| References to `/home/iperez/.tabularium/AI/skills/...` paths in pi-harness agents | pi-harness `assets/agents/*.md` body |
| Engram + Obsidian as default persistence, no `openspec/` in repos | `_shared/persistence-contract.md`, orchestrator artifact-store text |
| Inlined Engram protocol in per-client orchestrators | `claude/sdd-orchestrator.md`, `codex/sdd-orchestrator.md`, `opencode/ORCHESTRATOR.md`, `pi-harness/assets/orchestrator.md` |
| User-authored skills not present upstream: `obsidian`, `dbflux-release`, `find-skills`, `upstream-ai-sync` | canonical + every client mirror |
| User-authored agents: `bug-hunter`, `pr-reviewer` (claude/opencode) | `claude/agents/`, `opencode/agent/` |
| `author: iperez` in skill frontmatter | every skill SKILL.md |

## Hard Rules

- Work only in `/home/iperez/.tabularium/AI`, `/home/iperez/dev/personal/pi-harness`, `/home/iperez/.pi/agent`, and the upstream caches under `/home/iperez/.cache/tabularium-ai/`, unless the user names another target.
- Do not modify either upstream checkout except `git clone`, `git fetch`, `git pull --ff-only`, or read-only inspection.
- Snapshot before writing: copy current state of every target directory to `.logs/sync-YYYYMMDD-HHMMSS/` before any modification.
- For PRESENT_DRIFT files: classify the drift before acting. If drift is in the "preserved customizations" table above, KEEP local. If drift is in a section the user has not touched (visible from snapshot history) and upstream changed, ADOPT upstream content while re-applying preserved customizations. If drift is ambiguous, ASK the user.
- For MISSING_IN_USER files: copy from upstream, strip persona, apply customizations, write to user location. Mirror to each relevant client tree.
- For USER_ONLY files: if listed in "preserved customizations", KEEP. Otherwise flag for user decision; do not auto-delete.
- Sync whole skill packages, not only `SKILL.md`; preserve every file under the skill directory, including `assets/`, `references/`, and direct companion files (strict-TDD guides, etc.).
- Before syncing skills, inspect upstream `docs/skill-style-guide.md` if present and preserve new frontmatter fields such as `disable-model-invocation` and `user-invocable`.
- Resulting instruction assets must use neutral personality and remove visible branding/persona references unless the identifier is technically required.
- Obsidian and Engram are always the planning/spec persistence backends; do not write OpenSpec artifacts into a normal repo tree unless explicitly requested.
- An orchestrator must never delegate to another orchestrator; prefer non-blocking sub-agent delegation.
- Validate and repair expected symlinks before syncing content. Never replace a real file/directory without user approval.
- Do not sync generated validation fixtures, local runtime state, user backups, auth files, caches, or project planning artifacts unless the user explicitly asks for that exact target.
- Do not sync the pi-harness Engram extension surface from gentle-pi; engram is handled by `gentle-engram`. Touching `pi-harness/extensions/` requires explicit user instruction.
- Enforce provider parity: when upstream changes a behavior (engram protocol, SDD orchestrator rule, persona/branding contract), inspect every parallel file listed in `references/provider-parity.md` so the same behavior is present in all relevant provider variants and reported for the runtime-multiplexing pi-harness orchestrator.

## Provider Parity Protocol

The upstream toolkit ships one behavioral contract rendered as per-provider variants (claude/codex/opencode/generic). The sync skill MUST keep all variants in lockstep when a behavior changes, and MUST flag pi-harness `assets/orchestrator.md` updates (pi-harness is not in this skill's write scope, but its orchestrator is the runtime union of all provider variants). See `references/provider-parity.md` for the asset matrix, parallel file sets, per-provider formatting rules, and the pi-harness handling rule.

## Decision Gates

| Situation | Action |
|---|---|
| MISSING_IN_USER (upstream has, user lacks) | Copy upstream -> strip persona -> apply preserved customizations -> write to user location and every relevant client mirror. |
| PRESENT_1to1 (byte-identical) | No action. |
| PRESENT_DRIFT, drift matches preserved-customization table | KEEP local. |
| PRESENT_DRIFT, upstream-only changes in untouched sections | RESYNC content from upstream; re-apply preserved customizations. |
| PRESENT_DRIFT, both changed same section | ASK before writing unless purely mechanical (whitespace, em-dash normalization). |
| USER_ONLY in preserved-customization table | KEEP. |
| USER_ONLY not in table | FLAG for user decision; do not auto-delete. |
| Branding/persona content in upstream | STRIP during sync; never propagate to user files. |
| Persistence conflict | Obsidian + Engram wins. |
| Broken/missing symlink | Restore if expected target is known; otherwise ASK. |

## Execution Steps

1. Prepare/update both upstream caches; record commit SHAs for `upstream-ai-toolkit` and `gentle-pi`.
2. Snapshot every target tree under `.logs/sync-YYYYMMDD-HHMMSS/` BEFORE any write.
3. Inspect `internal/assets/assets.go` in gentle-ai to discover currently embedded asset roots. Inspect `assets/`, `extensions/`, `prompts/`, `skills/` in gentle-pi to discover its surface.
4. Inspect relevant adapter path logic under `internal/agents/*/adapter.go` before changing install targets, symlink assumptions, or validation rules.
5. Validate symlinks as legacy/external entry points, but do not assume symlinks are the primary install mechanism; gentle-ai often writes managed files directly into client config roots.
6. Inventory upstream surfaces:
   - gentle-ai: `internal/assets/skills/**`, root `skills/**`, `docs/skill-style-guide.md`, `docs/agents.md`, and per-client assets.
   - gentle-pi: `assets/agents/**`, `assets/chains/**`, `assets/support/**`, `assets/orchestrator.md`, `extensions/**`, `prompts/**`, `skills/**`.
7. Compare against local client-scoped packages under `/home/iperez/.tabularium/AI/{opencode,claude,codex,gemini,cursor,windsurf,antigravity,kimi,kiro,qwen,gga,copilot,kilo,openclaw,pi}/` plus pi-harness `assets/`/`extensions/` and `.pi/agent/`.
8. For each file, classify as PRESENT_1to1 / PRESENT_DRIFT / MISSING_IN_USER / USER_ONLY and apply the Decision Gates table.
9. After applying upstream updates, verify behavior changes are reflected across ALL provider files per `references/provider-parity.md`. Walk each parallel file set for the changed surface (engram, SDD orchestrator, persona, commands). Where pi-harness `assets/orchestrator.md` would need an update, emit an explicit "pi-harness update required" line with the exact paragraph(s) to add.
10. Validate skill frontmatter against upstream tests, recursive skill package copying, branding policy, neutral policy, Obsidian+Engram policy, no orchestrator-to-orchestrator delegation, non-blocking delegation preference, and symlink health.
11. Final validation: grep canonical and pi-harness for residual persona/branding strings (target: zero hits). Grep for `.atl/skill-registry` (target: zero hits). Confirm preserved customizations are intact.

## Output Contract

Return upstream cache path and commit, compared counts for skills/references/assets/commands/agents/orchestrators, updated files, kept-local files, conflicts requiring decision, and validation results.

## References

- `references/sync-details.md` — canonical paths, symlink targets, upstream locations, merge rules, and report template.
- `references/provider-parity.md` — per-provider standardization pattern, asset matrix, behavior contract rule, parallel file sets, pi-harness handling, and provider-specific adaptation rules (markdown dialect, tool surface, loader mechanism).
