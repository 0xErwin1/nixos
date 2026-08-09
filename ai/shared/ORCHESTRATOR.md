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

- Native bounded review governs the normal flow. Each provider's own orchestrator
  carries the full contract — route, receipt identity, normalization ordering, and
  delivery gates — and is authoritative over this summary.
- One immutable candidate permits at most one scoped correction. There is no
  loop-until-clean behavior, and gates never reopen review for unchanged content.
- Judgment Day remains a separate, explicit opt-in on top of native review; start it
  only when the user asks for it by name.

## Provider applicability

- Preserve provider-specific models, permissions, and tool mechanics in their own configuration.
- Keep language, secret handling, Engram recovery, and canonical-source rules in their designated global policies.
