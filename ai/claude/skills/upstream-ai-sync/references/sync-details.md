# Upstream AI Sync Details

## Canonical Paths

The single source of truth is the git-tracked Home Manager tree `@ai`. All sync writes land here.

| Purpose | Path |
|---|---|
| Canonical AI tree (`@ai`) | `/home/iperez/.config/home-manager/ai` |
| Shared/canonical skills | `/home/iperez/.config/home-manager/ai/skills` |
| Shared command dir | `/home/iperez/.config/home-manager/ai/command` |
| OpenCode assets | `/home/iperez/.config/home-manager/ai/opencode` |
| Claude assets | `/home/iperez/.config/home-manager/ai/claude` |
| Codex assets | `/home/iperez/.config/home-manager/ai/codex` |
| Shared authoring/contract layer | `/home/iperez/.config/home-manager/ai/shared` |
| Pi secret template | `/home/iperez/.config/home-manager/ai/pi/mcp.json` |
| Projection map (authoritative) | `/home/iperez/.config/home-manager/home-manager/global/ai-harness.nix` |
| Sync snapshots (outside git repo) | `/home/iperez/.cache/tabularium-ai/sync-snapshots` |
| gentle-ai upstream cache | `/home/iperez/.cache/tabularium-ai/upstream-ai-toolkit` |
| gentle-pi upstream cache | `/home/iperez/.cache/tabularium-ai/gentle-pi` |

`~/.tabularium/AI` is no longer a harness hub; it is Obsidian notes (`NOTES_DIR`) only. Do not write harness assets there.

Never keep an upstream git checkout under `@ai`; the upstream lives in the caches above.

## Nix Projection Model (runtime install)

This skill edits `@ai` sources only. Home Manager (`ai-harness.nix`) projects them to runtime locations from `/nix/store`, or renders secret templates at activation. Never write into the runtime targets; they are read-only store symlinks or activation-rendered files, and a projection preflight aborts `home-manager switch` if a target is an unmanaged file/symlink.

### Projected resources (`@ai` source -> runtime target)

Verbatim from `ai-harness.nix` `projectedResources`:

| Source under `ai/` | Runtime target | Recursive |
|---|---|---|
| `skills` | `.agents/skills` | yes |
| `opencode/AGENTS.md` | `.config/opencode/AGENTS.md` | no |
| `opencode/ORCHESTRATOR.md` | `.config/opencode/ORCHESTRATOR.md` | no |
| `opencode/agent` | `.config/opencode/agent` | yes |
| `opencode/commands` | `.config/opencode/commands` | yes |
| `command` | `.config/opencode/command` | yes |
| `opencode/prompts` | `.config/opencode/prompts` | yes |
| `opencode/skills` | `.config/opencode/skills` | yes |
| `opencode/tui.json` | `.config/opencode/tui.json` | no |
| `claude/CLAUDE.md` | `.claude/CLAUDE.md` | no |
| `claude/sdd-orchestrator.md` | `.claude/sdd-orchestrator.md` | no |
| `claude/engram-protocol.md` | `.claude/engram-protocol.md` | no |
| `claude/agents` | `.claude/agents` | yes |
| `claude/commands` | `.claude/commands` | yes |
| `claude/skills` | `.claude/skills` | yes |
| `codex/AGENTS.md` | `.codex/AGENTS.md` | no |
| `codex/sdd-orchestrator.md` | `.codex/sdd-orchestrator.md` | no |
| `codex/engram-instructions.md` | `.codex/engram-instructions.md` | no |
| `codex/engram-compact-prompt.md` | `.codex/engram-compact-prompt.md` | no |
| `codex/commands` | `.codex/commands` | yes |
| `codex/agents` | `.codex/agents` | yes |
| `codex/skills` | `.codex/skills` | yes |

Recursive resources materialize as a real directory whose leaf files are managed symlinks; single-file targets are whole-path symlinks. The unmanaged-collision preflight applies to single-file targets only.

### Secret-bearing configs (`@VAR@` placeholders, never real tokens)

Rendered or merged at activation from the secret env files (`~/.config/ai-harness/secrets/mcp.env`, `~/.config/ai-harness/secrets/api.env`). Preserve placeholder form; never expand or commit a secret value.

| Kind | `@ai` template | Runtime target |
|---|---|---|
| rendered (whole file) | `opencode/opencode.jsonc` | `.config/opencode/opencode.jsonc` |
| rendered (whole file) | `pi/mcp.json` | `.pi/agent/mcp.json` |
| merged (json MCP servers) | `claude/mcp-servers.json` | `.claude.json` |
| merged (toml MCP servers) | `codex/mcp-servers.toml` | `.codex/config.toml` |
| merged (json deep-merge) | `claude/settings-merge.json` | `.claude/settings.json` |

Merged configs inject only the owned section (MCP servers, or the settings subtree) into an agent-owned file and preserve the rest, because the agent rewrites that file at runtime.

## Managed Provider Subset

`@ai` manages only claude, codex, opencode, the shared `ai/skills` and `ai/command`, and `ai/pi/mcp.json`. Map upstream onto this subset:

| Upstream (gentle-ai) | `@ai` target |
|---|---|
| `internal/assets/claude/**` | `ai/claude` |
| `internal/assets/codex/**` | `ai/codex` |
| `internal/assets/opencode/**` | `ai/opencode` |
| `internal/assets/skills/**`, root `skills/**` | `ai/skills` and mirrors `ai/{claude,codex,opencode}/skills` |
| `internal/assets/generic/**` (behavioral contract) | `ai/shared` authoring layer |

Upstream also ships `gemini`, `cursor`, `kimi`, `kiro`, `qwen`, `windsurf`, `antigravity`, `gga`, `hermes`. These are intentionally NOT managed. Do not create them under `@ai`.

## `ai/shared/` authoring layer

`ai/shared/` is NOT projected. It is the canonical behavioral contract:

- `ai/shared/ORCHESTRATOR.md` — canonical SDD orchestrator contract.
- `ai/shared/AGENTS.md` — canonical global instructions contract.
- `ai/shared/engram-protocol.md` — canonical Engram protocol source.

The projected per-client copies must stay in parity with these by hand; nothing auto-generates them:

- `ai/opencode/ORCHESTRATOR.md`, `ai/claude/sdd-orchestrator.md`, `ai/codex/sdd-orchestrator.md` mirror `ai/shared/ORCHESTRATOR.md`.
- `ai/claude/engram-protocol.md`, `ai/codex/engram-instructions.md`, `ai/codex/engram-compact-prompt.md` render from `ai/shared/engram-protocol.md`.

## Pi boundary

`~/dev/personal/pi-harness` and `~/.pi/agent` are valid Pi targets handled separately; Pi runtime comes from the external pi-harness flake input, not from `@ai`. The only Pi asset in `@ai` is `ai/pi/mcp.json` (secret template -> `.pi/agent/mcp.json`). This skill does not write into the pi-harness repo; it flags required pi-harness orchestrator updates in its report.

## Snapshots

Snapshot every target tree to `~/.cache/tabularium-ai/sync-snapshots/YYYYMMDD-HHMMSS/` BEFORE any write. Never snapshot into `@ai` (it is git-tracked; snapshots would pollute the Nix config).

## Upstream Locations

Inspect these in the gentle-ai cache when present:

| Asset type | Upstream paths |
|---|---|
| Embedded skills | `internal/assets/skills/**` |
| Repository skills | `skills/**` |
| Skill style/rules | `docs/skill-style-guide.md` |
| Claude assets | `internal/assets/claude/**` |
| Codex assets | `internal/assets/codex/**` |
| OpenCode assets | `internal/assets/opencode/**` |
| Generic (behavioral contract source) | `internal/assets/generic/**` |
| OpenCode plugins/overlays | `internal/assets/opencode/plugins/**`, `internal/assets/opencode/sdd-overlay-*.json` |
| Client agents | `internal/assets/{claude,codex,opencode}/agents/**` |
| Client commands | `internal/assets/{claude,codex,opencode}/commands/**` |
| Embedded asset manifest | `internal/assets/assets.go` |
| Agent capability docs | `docs/agents.md` |
| Command registry/helpers | `internal/assets/commands.go` |
| v2.0 review runtime (not reproducible) | `internal/components/reviewtransaction` and related receipt/CAS/ledger code |

If a skill exists under `skills/**` but not under `internal/assets/skills/**`, treat the root skill as an additional source asset. Ignore upstream provider roots outside the managed subset.

## Skill Package Rules

Compare and merge complete skill directories:

```text
<skill>/
├── SKILL.md
├── assets/       # optional templates, schemas, fixtures, generated examples
├── references/   # optional local detail docs and edge cases
└── *.md / other direct companions
```

Do not flatten `references/` into `SKILL.md`. Keep references local and relative. Preserve upstream frontmatter additions unless they conflict with local policy. Preserve direct companion files such as `strict-tdd.md` and `strict-tdd-verify.md`; they are part of the package even though they are not under `assets/` or `references/`. Sync each managed skill to `ai/skills/` and to the client mirrors `ai/{claude,codex,opencode}/skills/`.

## Do Not Sync / Do Not Modify

- Upstream repository internals: `.git/**`.
- Anything under runtime dirs (`~/.claude`, `~/.config/opencode`, `~/.codex`, `~/.agents`, `~/.pi/agent`); these are Nix-managed.
- Snapshots except when creating a new one: `~/.cache/tabularium-ai/sync-snapshots/**`.
- Runtime locks and databases: `scheduled_tasks.lock`, `.engram/engram.db`, `.engram/cloud.json`.
- Skill resolver runtime output: `.agents/**` runtime state, unless the user explicitly asks to inspect generated registry state.
- Validation fixtures as runtime sync sources: `testdata/golden/**`.
- Project planning/spec history: `openspec/**`, unless the user explicitly asks to sync project SDD artifacts.
- User auth/cache files, state, and backups: auth JSON, model caches, `state.json`, `backups/**`.
- Real secret values: never write a resolved token into any secret-bearing config; keep `@VAR@` placeholders.

## Normalization Rules

- Remove visible branding/persona references from local policy-controlled instruction text.
- Preserve branded upstream source assets when they are intentional source material, then decide whether the local synced copy must be neutralized.
- Keep technical identifiers only when removing them would break paths, commands, package names, markers, URLs, imports, or config keys.
- Preserve model assignment, phase, command, and tool mechanics when still applicable.
- Local policy wins for neutral personality, Obsidian+Engram persistence, no orchestrator-to-orchestrator delegation, and non-blocking sub-agent delegation.
- For v2.0 runtime-backed behavior, port only the prompt-expressible portion; document the runtime-only remainder as not-reproducible.

## Validation Rules

- Validate skill frontmatter against upstream tests in `internal/assets/skills_frontmatter_test.go`: `name` must match the parent directory, `description` must be a quoted single-line scalar, descriptions must include `Trigger:`, descriptions must be no longer than 160 characters, and allowed top-level keys include `user-invocable` and `disable-model-invocation`.
- Validate recursive skill package copy, including `assets/`, `references/`, and direct companion files.
- Validate embedded asset coverage by checking `internal/assets/assets.go`; confirm managed-subset providers are covered and out-of-subset providers are ignored.
- Validate OpenCode plugin and overlay handling for `plugins/*.ts`, `sdd-overlay-*.json`, and multi-mode shared prompts.
- Validate `@VAR@` placeholder integrity in every secret-bearing config (no resolved secret values).
- Validate that no write targeted a runtime dir and no stray file was created at a projection target path.
- Validate that snapshots live under `~/.cache/tabularium-ai/sync-snapshots/`, never under `@ai`.

## Report Template

```markdown
## Upstream
- Cache path: ...
- Commit: ...

## Compared
- Skills: N
- Skill references/assets: N
- Commands: N
- Agents: N
- Orchestrator files: N
- OpenCode plugin/overlay assets: N

## Updated (@ai sources)
- path — summary

## Kept Local
- path — reason

## Conflicts / Needs Decision
- path — conflict and options

## Runtime-only (not reproducible)
- behavior — why it cannot be ported to prompt assets

## Validation
- Wrote only @ai sources (no runtime-dir writes): pass/fail
- No stray files at projection targets: pass/fail
- Secret configs keep @VAR@ placeholders: pass/fail
- Snapshots outside @ai: pass/fail
- Branding/persona references: pass/fail
- Neutral personality: pass/fail
- Obsidian + Engram policy: pass/fail
- No orchestrator-to-orchestrator delegation: pass/fail
- Non-blocking delegation preference: pass/fail
- Skill frontmatter rules: pass/fail
- Recursive skill package preservation: pass/fail
- Provider parity across claude/codex/opencode: pass/fail

## Deploy reminder
- Changes take effect only after `home-manager switch`.
```
