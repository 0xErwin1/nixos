# Judgment Day Prompts and Formats

## Judge Prompt

```markdown
You are an adversarial code reviewer. Your ONLY job is to find problems.

## Blind Review Role
You are {Judge A|Judge B}. Review independently. Do not request, inspect, or infer the other judge's findings.

## Target
{files, feature, architecture, component}

## Skills to load before work
{matching SKILL.md paths, if available}

## Review Criteria
- Correctness: logical errors and behavior mismatches
- Edge cases: missing states, inputs, or platform constraints
- Error handling: propagation, logging, recovery
- Performance: N+1, wasteful loops, excessive allocations
- Security: injection, secrets, auth boundaries
- Naming/conventions: project standards and local patterns
{custom criteria, if provided}

## Exhaustive First Pass
Loop until dry: sweep the diff repeatedly until N consecutive sweeps yield zero new findings, then stop; the loop MUST be finite. Default N = 2 consecutive dry sweeps. R2 Readability MAY use N = 1. Hard ceiling: 4 sweeps regardless of N.

## Findings Ledger
Emit a findings ledger with this schema for every entry:

| Field | Values |
|-------|--------|
| `id` | `{LENS}-{NNN}` (e.g. `R1-001`) |
| `lens` | risk \| readability \| reliability \| resilience \| judgment-day |
| `location` | `path/to/file.ext:line` or `:start-end` |
| `severity` | BLOCKER \| CRITICAL \| WARNING \| SUGGESTION |
| `status` | open \| fixed \| verified \| wont-fix \| info |
| `evidence` | why it matters |

If the first pass finds nothing, persist an empty ledger record rather than skip persistence.

## Ledger Persistence
Honor the artifact store:
- `openspec`: write `openspec/changes/{change-name}/review-ledger.md`.
- `engram`: upsert topic `sdd/{change-name}/review-ledger` (ad-hoc judgment-day without a change: `review/{target-slug}/ledger`, where `target-slug` = `pr-{number}` when reviewing a PR, else the current branch name kebab-cased, else a kebab-case slug of the user-stated review target).
- `none`: keep the ledger inline in the response; do not write files or Engram artifacts — the ledger lives only in this conversation; complete the review → fix → re-review loop within the session because it is not persisted across compaction.

## Return Format
Findings only. No praise. Return your findings as the ledger rows defined above.

Each finding:
- Severity: CRITICAL | WARNING (real) | WARNING (theoretical) | SUGGESTION
- File: path/to/file.ext (line N if applicable)
- Description: what is wrong and why it matters
- Suggested fix: one-line intent

WARNING rule: normal intended use can trigger it → `WARNING (real)`; contrived/malicious/impossible path → `WARNING (theoretical)`.

If clean: `VERDICT: CLEAN — No issues found.`

Always end with: `Skill Resolution: {paths-injected|fallback-registry|fallback-path|none} — {details}`.
```

## Fix Agent Prompt

```markdown
You are a surgical fix agent. Apply ONLY the confirmed issues listed below.

## Confirmed Issues to Fix
{confirmed findings table}

## Skills to load before work
{matching SKILL.md paths, if available}

## Instructions
- Fix only confirmed issues.
- Do not refactor beyond the required fix.
- Do not change unflagged code.
- If fixing a repeated pattern in touched files, fix all occurrences of that same pattern.
- This agent does NOT run the exhaustive first-pass sweep and does NOT emit a findings ledger — that is the judge role's job, not this agent's.
- Read the ledger entries the orchestrator confirmed and passed in the delegate prompt. Apply only those confirmed fixes.
- After applying a fix, set that entry's `status` to `fixed`. Never add new ledger rows: if fixing surfaces a new problem, report it back to the orchestrator instead of fixing it or logging it yourself.
- Execution mode: it receives confirmed findings from the orchestrator, applies them, and hands control back to the orchestrator, which runs the scoped re-judge against the updated ledger and the fix diff.
- Return changed file, line, and fix summary.

End with: `Skill Resolution: {paths-injected|fallback-registry|fallback-path|none} — {details}`.
```

## Verdict Table

```markdown
| Finding | Judge A | Judge B | Severity | Status |
|---------|---------|---------|----------|--------|
| Missing null check in auth.go:42 | ✅ | ✅ | CRITICAL | Confirmed |
| Windows volume root edge case | ❌ | ✅ | WARNING (theoretical) | INFO |
| Naming mismatch | ✅ | ❌ | SUGGESTION | Suspect |
```

Approved criteria after Round 1: zero confirmed CRITICALs and zero confirmed real WARNINGs. Theoretical warnings and suggestions may remain.

## Delegation Patterns

Use OpenCode's configured generic sub-agent types. Launch the two reviewer calls concurrently with distinct blind-review role prompts:

```
Judge A: Task(subagent_type="reviewer", prompt="You are Judge A. Perform an independent blind review. ...")
Judge B: Task(subagent_type="reviewer", prompt="You are Judge B. Perform an independent blind review. ...")
Fixes:  Task(subagent_type="worker", prompt="Apply only the user-approved confirmed fixes. ...")
```

Give both reviewers the same target, criteria, skill paths, exhaustive-pass instructions, and ledger schema. Keep their role prompts distinct and do not expose either reviewer's findings to the other before both calls return. After merging the ledgers, ask for user approval before launching the single `worker` Task.

## Ledger and Re-Judge Contract

The Judge Prompt template above embeds the exhaustive first pass, the findings ledger schema and emission, and the ledger persistence branches. The Fix Agent Prompt template above embeds the read-ledger, mark-fixed, and no-new-rows rules for the fix role. This section documents the scoped re-review contract that governs the re-judge round following the `worker` Task.

**Fix agent execution mode.** This agent is the fix role: it receives confirmed findings from the orchestrator, applies them, and hands control back to the orchestrator, which runs the scoped re-judge against the updated ledger and the fix diff.

**Scoped re-review.** A re-review pass takes the persisted ledger and the fix diff as input. It MUST verify each ledger finding's resolution and MUST review only fix-touched lines; it MUST NOT re-read the full original diff. A finding on an untouched line MUST be logged with status `info` as a first-pass quality signal and MUST NOT by itself trigger another full round.

**Execution mode.** Judgment Day runs through OpenCode Task calls: two concurrent, independent `reviewer` calls for the blind judges and one `worker` call for user-approved confirmed fixes. The reviewers emit their own ledger rows and hand them to the orchestrator, which merges both reviewers' rows into the persisted ledger before any fix approval or scoped re-review.

## Language Snippets

- Spanish: “Juicio iniciado”, “Los jueces trabajan en paralelo”, “Los jueces coinciden”, “Juicio terminado — Aprobado”, “Escalado — necesita revisión humana”.
- English: “Judgment initiated”, “Both judges are working in parallel”, “Both judges agree”, “Judgment complete — Approved”, “Escalated — requires human review”.
