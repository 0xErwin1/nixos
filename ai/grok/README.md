# Grok Build harness assets

Canonical sources projected by Home Manager into `~/.grok/`.

| Source | Runtime target |
|--------|----------------|
| `AGENTS.md` | `~/.grok/AGENTS.md` (global rules) |
| `ORCHESTRATOR.md` | `~/.grok/ORCHESTRATOR.md` (SDD detail; load on demand) |
| `agents/` | `~/.grok/agents/` |
| `mcp-servers.toml` | merged into `~/.grok/config.toml` (`[mcp_servers.*]`) |

## Supported adapter surface

Grok Build discovers the shared `ai/skills` projection at `~/.agents/skills`.
Use those skills directly when their own frontmatter and instructions permit it.
This harness does not project named `sdd-*` Grok agent profiles: the only
Grok-specific profiles are `worker` and `reviewer`.

Grok-specific notes:
- Subagents: `spawn_subagent` supports the projected `worker` and `reviewer`
  profiles, plus Grok's built-in `explore`, `general-purpose`, and `plan` types.
- SDD: shared `sdd-*` skills are available through shared-skill discovery; do
  not claim a dedicated SDD subagent exists unless one is projected and Grok
  resolves it.
- Reviews: **4R** and **Judgment Day** are separate explicit opt-ins. They use
  the projected `reviewer` profile with the requested review prompt.
- No RDD / `gentle-ai review` lifecycle in this harness.
