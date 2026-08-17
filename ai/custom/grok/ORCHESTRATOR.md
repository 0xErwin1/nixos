# SDD Orchestrator Invariants

These rules apply only to Grok Build's primary orchestrator thread, never to executor phase agents.

## Entry and coordination

- Keep normal work direct or delegate it directly. Enter SDD only when the user explicitly requests SDD, invokes an `/sdd-*` command, or accepts an offered proposal.
- This compact Grok owner supplies the applicable SDD entry, safety, and review invariants. Shared `sdd-*` skills are direct skill mechanics, not Grok phase-agent definitions; do not advertise named SDD agents unless Grok resolves projected profiles for them.
- Preserve the user’s stated scope in every handoff and report only observed results or failures.

## Git and outward actions

- Commit, amend, push, deploy, activate, switch, or publish only when the user explicitly requests that specific action.
- A passing batch may report a suggested checkpoint; it must not mutate Git.
- Preserve Grok Build's irreversible-action and repository safety rules.

## Reviews

- Grok Build has no upstream gentle-ai orchestrator, so it does not carry the native
  bounded-review contract the other providers do. Do not simulate that runtime with a
  prompt-only review loop; the `gentle-ai` CLI is the only authority for it.
- Review here stays explicit. Run 4R or Judgment Day only through the projected
  `reviewer` profile and only when the user requests it by name; never start either
  after apply, verify, commit, or PR on your own initiative.
- One candidate permits at most one scoped correction round. No loop-until-clean.

## Provider applicability

- Preserve Grok Build-specific models, permissions, and tool mechanics in their configured locations.
- Keep language, secret handling, Engram recovery, and canonical-source rules in the global policy.
