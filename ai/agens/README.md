# Agens harness assets

Agens gets the same harness as Claude, Codex, and OpenCode, but it cannot consume
the shared files unmodified and it cannot receive them as symlinks. This directory
holds the agens-shaped copy; `generate.py` produces it from the shared sources.

## Quick path

1. Edit the shared sources, never the generated files: `ai/shared/AGENTS.md`,
   `ai/claude/agents`, `ai/claude/commands`, `ai/command`, `ai/skills`.
2. Run `python3 ai/agens/generate.py`.
3. Run `home-manager switch` to copy the result into `~/.config/agens/`.

Generated and safe to overwrite: `AGENTS.md`, `agents/`, `commands/`, `skills/`.
Hand-maintained: `config.toml`, `generate.py`, this file.

## Why this tree exists

| Constraint | Consequence |
|------------|-------------|
| Agens refuses symlinked assets | Home Manager copies instead of projecting. `markdown.rs` rejects a symlinked definition and rejects its canonicalized path for escaping the root; the skill loader opens every directory and manifest with `O_NOFOLLOW`. A `home.file` projection would leave agens with an empty catalog. |
| Agent frontmatter differs | Claude agents have no `mode`, so agens rejects them outright. |
| `model` is validated | Claude's `model: inherit` / `opus` are not agens model identifiers, so the agent would be dropped as unavailable. The field is removed. |
| `description` is one bounded line | Agens caps it at 1024 characters and rejects control characters. Claude's multi-paragraph descriptions with `<example>` blocks are truncated at the first example or blank line. |
| Frontmatter takes strings and string lists only | A nested mapping or a boolean aborts the parse. Descriptions are JSON-quoted because an unquoted `": "` reads as a nested mapping. |
| A manifest must open with `---` | Skills that lead with an HTML marker comment have it moved below the frontmatter rather than deleted. |
| Agens has no tool allowlist | Claude's `tools:` list becomes agens `permissions:` deny rules over the tools it knows: read, write/edit, list, search, bash. |
| The `read` tool is confined to the project root | Nothing under `~/.config/agens/` can be opened by path, so every "read the file at X" instruction becomes "load the X skill". Rewriting `~/.claude/...` to `~/.config/agens/...` is not enough — it just moves a dead end. `upstream-ai-sync` is exempt: those references are its subject matter. |
| Only skills are reachable from outside the project | `_shared/` is repackaged as the `sdd-shared` skill with its documents under `references/`, and the SDD procedure as the `sdd-orchestrator` skill. A bare directory or a loose markdown file next to the config is unreachable. |

## Instruction loading

Agens reads `~/.config/agens/AGENTS.md` and the project root's `AGENTS.md`, in
that order, appending both after each agent's own prompt. Every catalog agent and
the headless `agens chat` parent turn receive them. There is no ancestor-directory
chain, so a monorepo subdirectory's `AGENTS.md` is not picked up.

The detailed SDD procedure is not always-on. `AGENTS.md` points at the
`sdd-orchestrator` skill and the agent loads it on demand, which keeps the
always-on prompt near 30 KB instead of 70 KB.

## Secrets and hand edits

`config.toml` here is an MCP fragment, not the whole file. Home Manager **merges**
it into `~/.config/agens/config.toml` at activation, owning the `[mcp.*]` tables
and nothing else. Placeholders are substituted from
`~/.config/ai-harness/secrets/mcp.env`. Never commit resolved token values.

Everything else in the target file survives each switch, so set `provider.type`,
`provider.model`, `agent.*`, and `[mcp_defaults]` by hand there. A whole-file
render was the first attempt and was wrong: it silently discarded exactly those
hand-set values on the next `home-manager switch`.

## Checklist after regenerating

- [ ] `generate.py` reported 0 skipped agents.
- [ ] No file outside `skills/upstream-ai-sync/` still mentions `~/.claude`.
- [ ] No instruction names a path under `~/.config/agens/` — every one of them names a skill.
- [ ] Every `<file>.md reference of the sdd-shared skill` mentioned anywhere exists under `skills/sdd-shared/references/`.
- [ ] `agens config doctor` reports the global config as loaded and `Status: valid`.
- [ ] Your hand-set `provider.model` is still in `~/.config/agens/config.toml` after the switch.
