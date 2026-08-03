# SDD Orchestrator Workflow

This workflow is lazy-loaded only for explicit SDD work. `ORCHESTRATOR.md` owns global coordination, safety gates, explicit review entry, and choice transport. Phase skills and `sdd-phase-common.md` own retrieval, persistence, and phase-local execution.

## Explicit SDD entry

Enter SDD only when the user invokes `/sdd-*`, requests SDD in natural language, or accepts an offered SDD proposal. Ordinary work remains direct.

For a new explicit SDD request, collect preflight choices, confirm initialization context, then begin with exploration and proposal. Apply requires an existing proposal, specification, design, and task artifact plus an explicit request to apply or continue. Missing artifacts route to their required planning phase; do not infer a phase from free text.

## Session preflight

Before an SDD phase, record one session decision block. The single `question` call must contain these three localized groups in this order:

1. Pace: Interactive, Automatic.
2. Artifacts: Engram, OpenSpec, Both.
3. Review: 400 lines, 800 lines, Other.

Use the canonical choice transport in `ORCHESTRATOR.md`. Ask the three groups in one native `question` call when possible. Map the answers to `interactive` or `auto`, `engram`, `openspec`, `hybrid`, or `none`, and a numeric review budget. Ask one follow-up only when Review is Other.

The preflight applies to `/sdd-new`, `/sdd-continue`, `/sdd-ff`, `/sdd-explore`, `/sdd-apply`, `/sdd-verify`, `/sdd-archive`, and explicit SDD testing-pipeline requests. Existing artifacts or installed skills do not replace the session decision block.

## Phases

```text
explore → proposal → specification + design → tasks → apply → verify → archive
```

- `sdd-new` begins exploration and proposal.
- `sdd-ff` completes planning through tasks.
- `sdd-continue` selects the next dependency-ready phase from the active artifact store.
- `sdd-apply` and `sdd-verify` operate only on the explicitly named change and task scope.
- `sdd-archive` runs only after all tasks are complete and final verification passes.

## Status and artifact routing

Resolve status before routing a change. For `engram`, resolve status manually with `mem_search` then `mem_get_observation`. For `openspec` or `hybrid`, the native dispatcher is authoritative when available. Route only from structured dependency state, `nextRecommended`, and blockers; never infer a phase from free text.

The `/sdd-status` command is read-only and uses the existing status contract. It does not launch executors or mutate artifacts.

## Skill injection

Resolve applicable skills once per session and pass exact `SKILL.md` paths to every phase executor. Pass the preflight choices, artifact references, artifact-store mode, exact assigned task IDs, and applicable skill paths. Use configured phase bindings; do not invent model assignments at runtime.

## Strict TDD forwarding

For every apply and verify launch, pass `strict_tdd_configured, runner_available, and applicable_behavioral_boundary` as separate facts. Forward Strict TDD only when all three are true. Otherwise direct the executor to Standard Mode; Standard Verify still runs every applicable test, build, and type check. This decision changes neither runtime/outward-action gates nor the explicit Git-mutation requirement.

## Pace and convergence

Interactive mode pauses after each phase result for the user's next instruction. Automatic mode proceeds only while the prior phase succeeded and its declared artifact is readable; it does not start 4R or Judgment Day.

Only BLOCKER or CRITICAL contract failures reopen work. Stop after two correction attempts for the same issue and report both attempts. A passed verification or user decision remains fixed unless the user accepts a scope change.

## Apply checkpoints

Batch only by coherent task boundaries, never by review-budget line count. For each batch:

1. Apply the exact assigned task IDs.
2. Verify that batch against its applicable specification and design scope.
3. Report the evidence, verdict, and next action.

The quiet batch cycle is `apply → verify → report`. It never starts 4R or Judgment Day automatically. Git mutation remains outside the cycle and requires an explicit user request.

## Exact apply scope and result reconciliation

Every apply launch names the exclusive task IDs. The executor implements only the assigned IDs, then stops. Before another batch or a completion report, reconcile the returned status, changed files, task artifact, and available evidence; report a scope deviation or mismatch instead of trusting prose.

## Apply-progress continuity

Before every continuation apply launch, check for `sdd/{change-name}/apply-progress`. If present, require the executor to read it, merge prior and new completion evidence, and persist the combined progress without overwriting earlier batches.

## Completion, escalation, and synthesis

Track worker progress while a phase runs. The parent records completion only after reconciling the result with artifacts and repository evidence. On a blocked, failed, escalated, or unreconciled result, preserve the completed state, report the blocker and next action, and do not advance dependent work. Synthesize verified phase results for the user; do not reclaim phase-local execution.

## Testing pipeline

The full SDD testing pipeline is explicit. `/sdd-test` or an explicit request for a reusable testing pipeline follows `explore-testing → suites approval → plan-testing → run-testing → report-testing`. A bare request to run tests stays a direct bounded action.

The suites approval is a user checkpoint. Do not launch planning or execution until the user approves the test cases and the selected execution context. Testing phase skills own their detailed prerequisites and artifact handling.
