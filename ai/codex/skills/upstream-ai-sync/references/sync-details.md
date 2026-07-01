# Upstream AI Sync Details

## Canonical Paths

| Purpose | Path |
|---|---|
| Personal AI workspace | `/home/iperez/.tabularium/AI` |
| Shared/reference skills | `/home/iperez/.tabularium/AI/skills` |
| OpenCode assets | `/home/iperez/.tabularium/AI/opencode` |
| Claude assets | `/home/iperez/.tabularium/AI/claude` |
| Codex assets | `/home/iperez/.tabularium/AI/codex` |
| Gemini assets | `/home/iperez/.tabularium/AI/gemini` |
| Cursor assets | `/home/iperez/.tabularium/AI/cursor` |
| VS Code Copilot assets | `/home/iperez/.tabularium/AI/copilot` |
| Kilo Code assets | `/home/iperez/.tabularium/AI/kilo` |
| Windsurf assets | `/home/iperez/.tabularium/AI/windsurf` |
| Antigravity assets | `/home/iperez/.tabularium/AI/antigravity` |
| Kimi assets | `/home/iperez/.tabularium/AI/kimi` |
| Kiro assets | `/home/iperez/.tabularium/AI/kiro` |
| Qwen assets | `/home/iperez/.tabularium/AI/qwen` |
| OpenClaw assets | `/home/iperez/.tabularium/AI/openclaw` |
| Pi metadata | `/home/iperez/.tabularium/AI/pi` |
| GGA assets | `/home/iperez/.tabularium/AI/gga` |
| Sync logs/snapshots | `/home/iperez/.tabularium/AI/.logs` |
| Upstream cache | `/home/iperez/.cache/tabularium-ai/upstream-ai-toolkit` |

Do not keep the upstream git checkout under `/home/iperez/.tabularium/AI`; that workspace is synchronized elsewhere.

## Client-Scoped Layout

| Client | Skills | Commands | Agents | Main instructions | Orchestrator |
|---|---|---|---|---|---|
| OpenCode | `opencode/skills` | `opencode/commands` | `opencode/agent` | `opencode/AGENTS.md` or shared `AGENTS.md` | `opencode/ORCHESTRATOR.md` or shared `ORCHESTRATOR.md` |
| Claude | `claude/skills` | `claude/commands` | `claude/agents` | `claude/CLAUDE.md` | `claude/sdd-orchestrator.md` |
| Codex | `codex/skills` | `codex/commands` if used | `codex/agents` if used | `codex/AGENTS.md` or shared `AGENTS.md` | `codex/sdd-orchestrator.md` or config fragment |
| Gemini CLI | `gemini/skills` | none by default | none by default | `gemini/GEMINI.md` | `gemini/sdd-orchestrator.md` |
| Cursor | `cursor/skills` | none by default | `cursor/agents` | `cursor/rules/gentle-ai.mdc` | `cursor/agents/sdd-*.md` |
| VS Code Copilot | `copilot/skills` | none by default | none by default | platform VS Code User prompts path | none by default |
| Kilo Code | OpenCode-compatible `kilo/skills` | `kilo/commands` | none by default | `kilo/AGENTS.md` | OpenCode-compatible config |
| Kimi | shared `agents/skills` or `kimi/skills` | none by default | `kimi/agents` | `kimi/KIMI.md` | `kimi/agents/sdd-*` |
| Kiro IDE | `kiro/skills` | none by default | `kiro/agents` | `kiro/steering/gentle-ai.md` | `kiro/agents/sdd-*.md` |
| Qwen Code | `qwen/skills` | `qwen/commands` | none by default | `qwen/QWEN.md` | `qwen/sdd-orchestrator.md` |
| Windsurf | `windsurf/skills` | none by default | none by default | `windsurf/memories/global_rules.md` | workspace `.windsurf/workflows/sdd-new.md` |
| Antigravity | `antigravity/skills` | none by default | none by default | shared Gemini-family `GEMINI.md` path | `antigravity/sdd-orchestrator.md` |
| OpenClaw | global `openclaw/skills` plus workspace SDD skills | none by default | none by default | workspace `AGENTS.md` and `SOUL.md` | workspace `.openclaw/skills/sdd-*` |
| Pi | package-managed | package-managed | package-managed | package-managed | package-managed |
| GGA | `gga` support files | none by default | none by default | `gga/AGENTS.md` | none by default |
| Shared/reference | `skills` | `commands` / `command` | none by default | `AGENTS.md` | `ORCHESTRATOR.md` |

When upstream separates assets by client, keep them separated locally. Shared files are allowed only when genuinely client-agnostic or intentionally symlinked.

## Expected Symlinks and Managed Targets

Gentle AI can write managed files directly into client config roots. Treat symlinks as legacy/external entry points to validate, not as the only install mechanism. Before changing any target path, inspect the matching adapter under `internal/agents/*/adapter.go` in the upstream checkout.

### Legacy Symlinks

| External path | Preferred target |
|---|---|
| `~/.config/opencode/skills` | `/home/iperez/.tabularium/AI/opencode/skills` |
| `~/.config/opencode/commands` | `/home/iperez/.tabularium/AI/opencode/commands` when present, else shared `commands` |
| `~/.config/opencode/command` | `/home/iperez/.tabularium/AI/opencode/command` when present, else shared `command` |
| `~/.config/opencode/agent` | `/home/iperez/.tabularium/AI/opencode/agent` |
| `~/.config/opencode/AGENTS.md` | `/home/iperez/.tabularium/AI/opencode/AGENTS.md` when present, else shared `AGENTS.md` |
| `~/.config/opencode/ORCHESTRATOR.md` | `/home/iperez/.tabularium/AI/opencode/ORCHESTRATOR.md` when present, else shared `ORCHESTRATOR.md` |
| `~/.claude/skills` | `/home/iperez/.tabularium/AI/claude/skills` |
| `~/.claude/commands` | `/home/iperez/.tabularium/AI/claude/commands` |
| `~/.claude/agents` | `/home/iperez/.tabularium/AI/claude/agents` |
| `~/.claude/CLAUDE.md` | `/home/iperez/.tabularium/AI/claude/CLAUDE.md` |
| `~/.codex/skills` | `/home/iperez/.tabularium/AI/codex/skills` |
| `~/.codex/AGENTS.md` | `/home/iperez/.tabularium/AI/codex/AGENTS.md` when present, else shared `AGENTS.md` |

Use `test -L`, `readlink`, and `realpath` before modifying links. If a symlink path is a real file/directory, ask before replacing it.

### Managed Install Targets to Consider

| Client | Important targets |
|---|---|
| Claude | `~/.claude/CLAUDE.md`, `~/.claude/skills`, `~/.claude/commands`, `~/.claude/agents`, `~/.claude/mcp/*.json`, `~/.claude/output-styles/gentleman.md` |
| OpenCode | `~/.config/opencode/AGENTS.md`, `~/.config/opencode/skills`, `~/.config/opencode/commands`, `~/.config/opencode/opencode.json`, `~/.config/opencode/plugins/*.ts`, `~/.config/opencode/prompts/sdd/*.md` |
| Kilo Code | OpenCode-compatible layout under `~/.config/kilo` |
| Gemini CLI | `~/.gemini/GEMINI.md`, `~/.gemini/skills`, `~/.gemini/settings.json` |
| Cursor | `~/.cursor/rules/gentle-ai.mdc`, `~/.cursor/skills`, `~/.cursor/agents/sdd-*.md`, `~/.cursor/mcp.json` |
| VS Code Copilot | `~/.copilot/skills`, platform VS Code User prompts path, platform VS Code User `mcp.json` |
| Codex | `~/.codex/agents.md`, `~/.codex/skills`, `~/.codex/config.toml`, `~/.codex/engram-instructions.md` |
| Windsurf | `~/.codeium/windsurf/skills`, `~/.codeium/windsurf/mcp_config.json`, `~/.codeium/windsurf/memories/global_rules.md`, workspace `.windsurf/workflows/sdd-new.md` |
| Antigravity | `~/.gemini/antigravity/skills`, `~/.gemini/antigravity/mcp_config.json`, shared `~/.gemini/GEMINI.md` append path |
| Kimi | `~/.kimi/KIMI.md`, `~/.kimi/agents/*.{yaml,md}`, `~/.kimi/mcp.json`, shared `~/.config/agents/skills` |
| Kiro IDE | `~/.kiro/steering/gentle-ai.md`, `~/.kiro/skills`, `~/.kiro/agents/sdd-*.md`, `~/.kiro/settings/mcp.json`, platform-specific app settings path |
| Qwen Code | `~/.qwen/QWEN.md`, `~/.qwen/skills`, `~/.qwen/settings.json`, `~/.qwen/commands` |
| OpenClaw | global `~/.openclaw/openclaw.json`, workspace `AGENTS.md`, workspace `SOUL.md`, workspace `.openclaw/skills/sdd-*`, global portable skills |
| Pi | `~/.pi`, `~/.pi/agent/settings.json`, `~/.pi/npm/package.json`, package-managed `.pi/agents`, `.pi/chains`, `.pi/gentle-ai/support` |

## Upstream Locations

Inspect these when present:

| Asset type | Upstream paths |
|---|---|
| Embedded skills | `internal/assets/skills/**` |
| Repository skills | `skills/**` |
| Skill style/rules | `docs/skill-style-guide.md` |
| OpenCode assets | `internal/assets/opencode/**` |
| Claude assets | `internal/assets/claude/**` |
| Codex assets | `internal/assets/codex/**` |
| Gemini assets | `internal/assets/gemini/**` |
| Cursor assets | `internal/assets/cursor/**` |
| GGA assets | `internal/assets/gga/**` |
| Kimi assets | `internal/assets/kimi/**` |
| Kiro assets | `internal/assets/kiro/**` |
| Qwen assets | `internal/assets/qwen/**` |
| Windsurf assets | `internal/assets/windsurf/**` |
| Antigravity assets | `internal/assets/antigravity/**` |
| Generic fallback | `internal/assets/generic/**` |
| OpenCode plugins/overlays | `internal/assets/opencode/plugins/**`, `internal/assets/opencode/sdd-overlay-*.json` |
| Client agents | `internal/assets/*/agents/**` |
| Client commands | `internal/assets/*/commands/**` |
| Windsurf workflows | `internal/assets/windsurf/workflows/**` |
| Embedded asset manifest | `internal/assets/assets.go` |
| Agent install adapters | `internal/agents/*/adapter.go` |
| Agent capability docs | `docs/agents.md` |
| Command registry/helpers | `internal/assets/commands.go` |

If a skill exists under `skills/**` but not under `internal/assets/skills/**`, treat the root skill as an additional source asset.

## Skill Package Rules

Compare and merge complete skill directories:

```text
<skill>/
├── SKILL.md
├── assets/       # optional templates, schemas, fixtures, generated examples
├── references/   # optional local detail docs and edge cases
└── *.md / other direct companions
```

Do not flatten `references/` into `SKILL.md`. Keep references local and relative. Preserve upstream frontmatter additions unless they conflict with local policy. Preserve direct companion files such as `strict-tdd.md` and `strict-tdd-verify.md`; they are part of the package even though they are not under `assets/` or `references/`.

## Do Not Sync / Do Not Modify

- Upstream repository internals: `.git/**`.
- Local sync logs and snapshots except when creating a new snapshot: `.logs/**`.
- Runtime locks and databases: `.claude/scheduled_tasks.lock`, `.engram/engram.db`, `.engram/cloud.json`.
- Skill resolver runtime output: `.agent/**`, unless the user explicitly asks to inspect generated registry state.
- Validation fixtures as runtime sync sources: `testdata/golden/**`.
- Project planning/spec history: `openspec/**`, unless the user explicitly asks to sync project SDD artifacts.
- User auth/cache files: `~/.local/share/opencode/auth.json`, `~/.cache/opencode/models.json`.
- User state/backups: `~/.gentle-ai/state.json`, `~/.gentle-ai/backups/**`.

## Normalization Rules

- Remove visible branding/persona references from local policy-controlled instruction text.
- Preserve branded upstream source assets when they are intentional source material, then decide whether the local synced copy must be neutralized.
- Keep technical identifiers only when removing them would break paths, commands, package names, markers, URLs, imports, or config keys.
- Preserve model assignment, phase, command, and tool mechanics when still applicable.
- Local policy wins for neutral personality, Obsidian+Engram persistence, no orchestrator-to-orchestrator delegation, and non-blocking sub-agent delegation.

## Validation Rules

- Validate skill frontmatter against upstream tests in `internal/assets/skills_frontmatter_test.go`: `name` must match the parent directory, `description` must be a quoted single-line scalar, descriptions must include `Trigger:`, descriptions must be no longer than 160 characters, and allowed top-level keys include `user-invocable` and `disable-model-invocation`.
- Validate recursive skill package copy, including `assets/`, `references/`, and direct companion files.
- Validate embedded asset coverage by checking `internal/assets/assets.go`.
- Validate OpenCode plugin and overlay handling for `plugins/*.ts`, `sdd-overlay-*.json`, and multi-mode shared prompts.
- Validate OpenClaw global/workspace split before syncing OpenClaw assets.
- Validate Antigravity/Gemini shared `GEMINI.md` collision handling.
- Validate Kiro split-root settings paths before changing Kiro targets.
- Validate Kimi shared skills root handling for `~/.config/agents/skills`.

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
- Client plugin/overlay assets: N
- Managed install targets reviewed: N

## Updated
- path — summary

## Kept Local
- path — reason

## Conflicts / Needs Decision
- path — conflict and options

## Validation
- Symlinks: pass/fail
- Branding/persona references: pass/fail
- Neutral personality: pass/fail
- Obsidian + Engram policy: pass/fail
- No orchestrator-to-orchestrator delegation: pass/fail
- Non-blocking delegation preference: pass/fail
- Skill frontmatter rules: pass/fail
- Recursive skill package preservation: pass/fail
- Client-specific install target review: pass/fail
```
