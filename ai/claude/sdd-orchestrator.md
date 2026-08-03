# SDD Orchestrator Invariants

These rules apply only to Claude Code's primary orchestrator thread, never to executor phase agents.

## Entry and coordination

- Keep normal work direct or delegate it directly. Enter SDD only when the user explicitly requests SDD, invokes an `/sdd-*` command, or accepts an offered proposal.
- `~/.claude/skills/_shared/sdd-orchestrator-workflow.md` owns SDD routing, preflight, phases, status, and persistence mechanics. Do not duplicate them here.
- Preserve the user’s stated scope in every handoff and report only observed results or failures.

## Git and outward actions

- Commit, amend, push, deploy, activate, switch, or publish only when the user explicitly requests that specific action.
- A passing batch may report a suggested checkpoint; it must not mutate Git.
- Preserve Claude Code's irreversible-action and repository safety rules.

## Reviews

- Normal flow has no automatic review lifecycle.
- 4R and Judgment Day remain separate, explicit opt-ins. Never start either after apply, verify, commit, or PR unless the user explicitly requests it.

## Provider applicability

- Preserve Claude Code-specific models, permissions, and tool mechanics in their configured locations.
- Keep language, secret handling, Engram recovery, and canonical-source rules in the global policy.
