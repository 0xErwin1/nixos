# Agens harness generation

`generate.py` builds the copied Agens harness from explicit semantic owners. It
does not regenerate the canonical tree during validation and never changes the
hand-managed `config.toml`.

## Quick path

1. Change an owner under `ai/shared/`, `ai/opencode/`, `ai/claude/`, or `ai/skills/`.
2. Run `python3 ai/agens/generate.py` to replace only generated outputs.
3. Run `python3 ai/agens/generate.py --check` to prove the generated tree is current.

The generated set is exactly `AGENTS.md`, `agents/`, `commands/`, and `skills/`.
`config.toml`, `generate.py`, and this README are protected.

## Ownership fusion

| Surface | Owner | Agens adaptation |
|---|---|---|
| Global policy | `ai/shared/AGENTS.md` | Kept once, including the single CodeGraph contract. |
| SDD entry, coordination, tools, safety, and reviews | `ai/opencode/ORCHESTRATOR.md` | Added without its duplicate CodeGraph block; filesystem workflow loading becomes a skill load. |
| Lazy workflow and phase mechanics | `ai/claude/skills/_shared/sdd-orchestrator-workflow.md` | Packaged only as `sdd-orchestrator`; Claude model-routing instructions are removed. |
| Phase agents and commands | `ai/claude/{agents,commands}` plus `ai/command` | Agent frontmatter and permissions are translated to native Agens syntax. |
| Shared skills and contracts | `ai/skills/`, required Claude testing skills, and selected `_shared` references | Copied as files; `_shared` becomes the loadable `sdd-shared` skill. |

No whole file is copied from Codex. Agens uses its native agent definitions and
configuration for model selection; generated instructions never request a
per-call Claude model alias.

## Agens adapters

- Skills are addressed by name because the reader is project-root confined.
- Claude `AskUserQuestion` instructions become a single grouped blocking choice
  prompt when available, with a complete chat-and-wait fallback otherwise.
- Claude agent `tools:` allowlists become Agens deny permissions where possible.
- HTML preambles move after skill frontmatter so copied manifests remain valid.
- `--check` stages a full tree in a temporary sibling directory, compares exact
  file sets and bytes, and writes nothing to `ai/agens/`.

## Safe validation

Run `python3 tests/ai-agens-generation.py`. The test copies `ai/` to a temporary
sandbox, runs generation and `--check` only there, injects stale and drift files,
and verifies the canonical `ai/agens/` tree and `config.toml` hashes are unchanged.

Activation is deliberately outside this generator. Do not edit runtime files
under `~/.config/agens/`; Home Manager owns their deployment.
