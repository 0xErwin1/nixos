---
name: judgment-day
description: "Trigger: judgment day, judgement day, dual review, adversarial review, juzgar. Run blind dual review, fix confirmed issues, then re-judge."
license: Apache-2.0
metadata:
  author: iperez
  version: "1.4"
---

## Activation Contract

Load this skill only when the user explicitly asks for Judgment Day, Judgement Day, dual/adversarial review, or equivalent Spanish trigger (`juzgar`, `que lo juzguen`). Review a specific target: files, feature, PR, or architecture slice. Judgment Day replaces ordinary 4R for that target; never run both.

## Hard Rules

- Resolve project skills before launching agents: read skill registry, match skill paths by target files/task, and inject the same `Skills to load before work` block into both judge prompts and fix prompts.
- Launch **two blind judges in parallel** with identical target and criteria; never review the code yourself.
- Wait for both judges before synthesis; never accept a partial verdict.
- Classify warnings as `WARNING (real)` only if normal intended use can trigger them; otherwise downgrade to INFO as `WARNING (theoretical)`.
- Ask before fixing Round 1 confirmed issues.
- After any fix agent runs, immediately re-launch both judges in parallel before commit/push/done/session summary.
- Terminal states are only `JUDGMENT: APPROVED` or `JUDGMENT: ESCALATED`.
- Permit at most two fix rounds and two scoped re-judgments; any issue remaining after round two escalates and stops.
- Never launch `review-refuter`; two-judge agreement is the corroboration mechanism.

## Decision Gates

| Condition | Action |
|---|---|
| Target unclear | Ask for scope; do not launch judges. |
| No skill registry | Warn, proceed with generic criteria, and record `Skill Resolution: none`. |
| Both judges find same CRITICAL/real WARNING | Confirmed; ask/fix according to round rules. |
| One judge finds issue | Suspect; report and triage, do not auto-fix. |
| Judges contradict | Escalate for manual decision. |
| Round 2+ has only theoretical warnings/suggestions | Report as INFO; do not re-judge. |

## Execution Steps

1. Confirm target and optional custom criteria.
2. Resolve exact skill paths from registry or warn if missing.
3. Start Judge A and Judge B concurrently via delegation; each runs the exhaustive first pass and emits its own findings ledger.
4. Synthesize findings into confirmed, suspect, contradiction, and INFO buckets; merge both judges' ledger rows into the persisted ledger and persist per the artifact-store branch.
5. Ask before Round 1 fixes; delegate a separate fix agent for confirmed approved fixes only. The fix agent reads the persisted ledger, applies only confirmed fixes, and sets addressed ledger ids to `fixed`.
6. Re-judge in parallel after fixes, scoped to the persisted ledger and the fix diff per the Scoped re-review contract; permit at most two fix rounds and two scoped re-judgments, then escalate and stop.
7. Before any terminal action, verify every active Judgment Day has a terminal state.

## Output Contract

Return `## Judgment Day — {target}` with round number, verdict table, confirmed/suspect/contradiction counts, fixes applied, ledger persistence location, re-judgment result, `Skill Resolution`, and final `JUDGMENT: APPROVED ✅` or `JUDGMENT: ESCALATED ⚠️`.

## Ledger and Re-Judge Contract

**Sweep budget.** Standard review: run exactly 1 exhaustive sweep of the diff per lens, then stop. Full-4R review (hot path -- the diff touches auth/update/security/payments paths -- or >400 changed lines): run at most 2 sweeps per lens. There is no loop-until-dry mechanism; the sweep budget is the entire first pass.

**Findings ledger.** Emit a findings ledger with this schema for every entry:

| Field | Values |
|-------|--------|
| `id` | `{LENS}-{NNN}` (e.g. `R1-001`) |
| `lens` | risk \| readability \| reliability \| resilience \| judgment-day |
| `location` | `path/to/file.ext:line` or `:start-end` |
| `severity` | BLOCKER \| CRITICAL \| WARNING \| SUGGESTION |
| `status` | open \| fixed \| verified \| wont-fix \| info |
| `evidence` | why it matters |

If the first pass finds nothing, persist an empty ledger record rather than skip persistence.

**Ledger persistence honors the artifact store.**
- `openspec`: write `openspec/changes/{change-name}/review-ledger.md`.
- `engram`: upsert topic `sdd/{change-name}/review-ledger` (ad-hoc judgment-day without a change: `review/{target-slug}/ledger`, where `target-slug` = `pr-{number}` when reviewing a PR, else the current branch name kebab-cased, else a kebab-case slug of the user-stated review target).
- `none`: keep the ledger inline in the response; do not write files or Engram artifacts — the ledger lives only in this conversation; complete the review → fix → re-review loop within the session because it is not persisted across compaction.

**Frozen re-judgment boundary.** Freeze the original corroborated BLOCKER/CRITICAL IDs, initial path set, acceptance criteria, and required regression evidence before correction. The fix agent may address only those IDs and paths. Re-judgment receives the frozen ledger and fix diff, verifies those IDs, the original criteria/tests, and correction regression evidence, and does not conduct general defect discovery or reopen unrelated defects. New observations are non-blocking follow-ups; a failed original criterion escalates the existing judgment.

**Execution mode.** Judgment-day judges run as delegated agents; when the runtime provides named `jd-*` sub-agents, those agents emit their own ledger rows and hand them to the orchestrator, which merges both judges' rows into the persisted ledger. Otherwise, the orchestrator runs both judges via generic delegate and maintains the merged ledger directly.

## References

- [references/prompts-and-formats.md](references/prompts-and-formats.md) — judge/fix prompts, warning rubric, verdict tables, and language snippets.
