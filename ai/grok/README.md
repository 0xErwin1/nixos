# Grok Build harness assets

Canonical sources projected by Home Manager into `~/.grok/`.

| Source | Runtime target |
|--------|----------------|
| `AGENTS.md` | `~/.grok/AGENTS.md` (global rules) |
| `ORCHESTRATOR.md` | `~/.grok/ORCHESTRATOR.md` (SDD detail; load on demand) |
| `agents/` | `~/.grok/agents/` |
| `mcp-servers.toml` | merged into `~/.grok/config.toml` (`[mcp_servers.*]`) |

Shared skills remain at `ai/skills` → `~/.agents/skills`, which Grok also discovers.

Grok-specific notes:
- Subagents: `spawn_subagent` with types `worker`, `reviewer`, `explore`, `general-purpose`, `plan`.
- Reviews: **4R** and **Judgment Day** are separate explicit opt-ins (see `AGENTS.md` / `ORCHESTRATOR.md`).
- No RDD / `gentle-ai review` lifecycle in this harness.
