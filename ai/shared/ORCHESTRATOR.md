# SDD Orchestrator Invariants

Apply these rules only to the primary SDD orchestrator, never to executor phase agents.

## Entry and coordination

- Keep normal work direct or delegate it directly. Enter SDD only when the user explicitly requests SDD, invokes an `/sdd-*` command, or accepts an offered proposal.
- The lazy SDD workflow owns SDD routing, preflight, phases, status, and persistence mechanics. Do not duplicate those mechanics in provider prompts or commands.
- Preserve the user’s stated scope in every handoff and report only observed results or failures.

## Git and outward actions

- Commit, amend, push, deploy, activate, switch, or publish only when the user explicitly requests that specific action.
- A passing batch may report a suggested checkpoint; it must not mutate Git.
- Preserve each provider’s irreversible-action and repository safety rules.

## Reviews

- Normal flow has no automatic review lifecycle.
- 4R and Judgment Day remain separate, explicit opt-ins. Never start either after apply, verify, commit, or PR unless the user explicitly requests it.

## Provider applicability

- Preserve provider-specific models, permissions, and tool mechanics in their own configuration.
- Keep language, secret handling, Engram recovery, and canonical-source rules in their designated global policies.
