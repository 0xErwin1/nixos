# SDD Orchestrator Workflow (lazy-loaded)

This is the detailed SDD + Testing procedure for the orchestrator. It is read on demand: the always-on `CLAUDE.md` keeps only the orchestrator role, delegation rules, and anti-patterns, and points here before any SDD command, SDD/Judgment-Day phase delegation, or testing-pipeline intent.

The orchestrator role and Delegation Rules defined in `CLAUDE.md` still apply; this file does not repeat them.

---

## SDD Workflow (Spec-Driven Development)

SDD is the structured planning layer for substantial changes.

### Artifact Store Policy

- `engram` -- default when available; persistent memory across sessions
- `openspec` -- file-based artifacts; use only when user explicitly requests
- `hybrid` -- both backends; cross-session recovery + local files; more tokens per op
- `none` -- return results inline only; recommend enabling engram or openspec

### Commands

Skills (appear in autocomplete):
- `/sdd-init` -> initialize SDD context; detects stack, bootstraps persistence
- `/sdd-explore <topic>` -> investigate an idea; reads codebase, compares approaches; no files created
- `/sdd-status [change]` -> read-only structured status for the active change, artifacts, tasks, and next action
- `/sdd-apply [change]` -> implement tasks in batches; checks off items as it goes
- `/sdd-verify [change]` -> validate implementation against specs; reports CRITICAL / WARNING / SUGGESTION
- `/sdd-archive [change]` -> close a change and persist final state in the active artifact store 
- `/sdd-onboard` -> guided end-to-end walkthrough of SDD using your real codebase

Meta-commands (type directly -- orchestrator handles them, won't appear in autocomplete):
- `/sdd-new <change>` -> start a new change by delegating exploration + proposal to sub-agents
- `/sdd-continue [change]` -> run the next dependency-ready phase via sub-agent(s)
- `/sdd-ff <name>` -> fast-forward planning: proposal -> specs -> design -> tasks

`/sdd-new`, `/sdd-continue`, and `/sdd-ff` are meta-commands handled by YOU. Do NOT invoke them as skills.

### Status-First Routing Guard

Before routing, continuing, applying, verifying, or archiving an SDD change, produce structured status first by reading `~/.codex/skills/_shared/sdd-status-contract.md` and following it against the active artifact store (engram by default). Route ONLY by `nextRecommended` and the dependency states; never infer routing from free text. If `blockedReasons` is non-empty, do not proceed to apply, archive, or terminal work. If `nextRecommended` is `verify`, verification/remediation may run only to refresh evidence; if it is `resolve-blockers`, report `blockedReasons` and stop. Carry `contextFiles`, task progress, dependency states, and `actionContext` (allowed edit roots) into every sub-agent launch.

### SDD Init Guard (MANDATORY)

Before executing ANY SDD command (`/sdd-new`, `/sdd-ff`, `/sdd-continue`, `/sdd-explore`, `/sdd-status`, `/sdd-apply`, `/sdd-verify`, `/sdd-archive`, `/sdd-test`, `/sdd-explore-testing`, `/sdd-plan-testing`, `/sdd-run-testing`, `/sdd-report-testing`) or any conversational testing-intent entry (natural-language trigger that maps to the testing pipeline), check if `sdd-init` has been run for this project:

1. Search Engram: `mem_search(query: "sdd-init/{project}", project: "{project}")`
2. If found -> init was done, proceed normally
3. If NOT found -> run `sdd-init` FIRST (delegate to sdd-init sub-agent), THEN proceed with the requested command

This ensures:
- Testing capabilities are always detected and cached
- Strict TDD Mode is activated when the project supports it
- The project context (stack, conventions) is available for all phases

Do NOT skip this check. Do NOT ask the user -- just run init silently if needed.

### Execution Mode

When the user invokes `/sdd-new`, `/sdd-ff`, or `/sdd-continue` for the first time in a session, ASK which execution mode they prefer:

- **Automatic** (`auto`): Run all phases back-to-back without pausing. Show the final result only. Use this when the user wants speed and trusts the process.
- **Interactive** (`interactive`): After each phase completes, show the result summary and ASK: "Want to adjust anything or continue?" before proceeding to the next phase. Use this when the user wants to review and steer each step.

If the user doesn't specify, default to **Interactive** (safer, gives the user control).

Cache the mode choice for the session -- don't ask again unless the user explicitly requests a mode change.

In **Interactive** mode, between phases:
1. Show a concise summary of what the phase produced
2. List what the next phase will do
3. Ask: "¿Continuamos? / Continue?" -- accept YES/continue, NO/stop, or specific feedback to adjust
4. If the user gives feedback, incorporate it before running the next phase

Interactive approval is phase-scoped. A reply such as "continue", "dale", or "go on" approves only the immediate next phase, not the rest of the SDD pipeline. Do not treat a generated artifact as approved until the user has had a chance to review it or explicitly delegate that review.

Before the propose phase in interactive mode, offer the user a proposal question round instead of silently deciding whether the proposal is clear enough. Explain that the questions are meant to improve the PRD/proposal by uncovering business understanding, business rules, implications, impact, edge cases, and product tradeoffs. Prefer 3-5 concrete product questions per round, then summarize the resulting assumptions and ask whether the user wants to correct anything or run a second round. Cover business and product decisions: business problem, target users and situations, business rules, product outcome, current-state gap, implications and impact, edge cases, decision gaps, first-slice scope boundaries, non-goals, product constraints, and business tradeoffs. Do not ask about test commands, PR shape, changed-line budget, or other harness mechanics at proposal time unless the user explicitly asks to discuss delivery.

For this agent (sub-agent delegation): **Automatic** means phases run back-to-back via sub-agents without pausing. **Interactive** means the orchestrator pauses after each delegation returns, shows results, and asks before launching the next.

### Artifact Store Mode

When the user invokes `/sdd-new`, `/sdd-ff`, or `/sdd-continue` for the first time in a session, ALSO ASK which artifact store they want for this change:

- **`engram`**: Fast, no files created. Artifacts live in engram only. Best for solo work and quick iteration. Note: re-running a phase overwrites the previous version (no history).
- **`openspec`**: File-based. Creates `openspec/` directory with full artifact trail. Committable, shareable with team, full git history.
- **`hybrid`**: Both -- files for team sharing + engram for cross-session recovery. Higher token cost.

If the user doesn't specify, detect: if engram is available -> default to `engram`. Otherwise -> `none`.

Cache the artifact store choice for the session. Pass it as `artifact_store.mode` to every sub-agent launch.

### Delivery Strategy

On the first `/sdd-new`, `/sdd-ff`, or `/sdd-continue` in a session, ask once for and cache delivery strategy: `ask-on-risk` (default), `auto-chain`, `single-pr`, or `exception-ok`. Pass it as `delivery_strategy` to `sdd-tasks` and `sdd-apply` prompts.

### Dependency Graph
```
proposal -> specs --> tasks -> apply -> verify -> archive
             ^
             |
           design
```

### Result Contract
Each phase returns: `status`, `executive_summary`, `artifacts`, `next_recommended`, `risks`, `skill_resolution`.

### Review Workload Guard (MANDATORY)

After `sdd-tasks` completes and before launching `sdd-apply`, inspect `Review Workload Forecast`.

If it says `Chained PRs recommended: Yes`, `400-line budget risk: High`, estimated changed lines exceed 400, or `Decision needed before apply: Yes`, apply cached `delivery_strategy`:

- **`ask-on-risk`**: STOP and ask chained/stacked PRs vs maintainer-approved `size:exception`.
- **`auto-chain`**: Do not ask. Tell `sdd-apply` to implement only the next autonomous chained/stacked PR slice using work-unit commits.
- **`single-pr`**: STOP and require/record `size:exception` before apply.
- **`exception-ok`**: Continue, but tell `sdd-apply` this run uses `size:exception`.

Automatic mode does not override this guard. Always pass the resolved delivery strategy to `sdd-apply`.

<!-- tabularium-ai:sdd-model-assignments -->
## Model Assignments

Read this table at session start (or before first delegation), cache it for the session, and pass the mapped alias in every Agent tool call via the `model` parameter. If a phase is missing, use the `default` row. If you lack access to the assigned model, substitute `sonnet` and continue.

| Phase | Default Model | Reason |
|-------|---------------|--------|
| orchestrator | opus | Coordinates, makes decisions |
| sdd-explore | sonnet | Reads code, structural - not architectural |
| sdd-propose | fable | Architectural decisions — most demanding reasoning |
| sdd-spec | opus | Structured writing |
| sdd-design | fable | Architecture decisions — most demanding reasoning |
| sdd-tasks | sonnet | Mechanical breakdown |
| sdd-apply | sonnet | Implementation |
| sdd-apply (visual/design slice) | opus | UI/visual/design work — sonnet tends to produce weak designs |
| sdd-verify | opus | Validation against spec |
| sdd-archive | haiku | Copy and close |
| sdd-explore-testing | sonnet | Codebase reading, structural - not architectural |
| sdd-plan-testing | sonnet | Structured writing |
| sdd-run-testing | sonnet | Implementation and execution |
| sdd-run-testing (visual diff) | opus | Screenshot capture + design-spec interpretation needs the strongest vision |
| sdd-report-testing | sonnet | Structured writing |
| default | sonnet | Non-SDD general delegation |

<!-- /tabularium-ai:sdd-model-assignments -->

**Conditional model for `sdd-run-testing`:** the orchestrator resolves the sub-agent model AFTER `plan-testing` returns, based on the plan contents:
- If the plan contains at least one case with `visual diff: yes`, launch `sdd-run-testing` with `opus` — interpreting captured screenshots against the design reference benefits most from the strongest vision model. This holds for both user-facing UI engines here: a `playwright` visual run captures styles and screenshots via the CLI, and a `maestro` visual run captures device/browser evidence through Maestro MCP or CLI.
- Otherwise (backend, api, or browser cases with no design reference), launch with `sonnet` — these are mechanical execution and gain nothing from a larger model.

**Conditional model for `sdd-apply` (local policy):** the orchestrator inspects the tasks artifact BEFORE launching apply. If it contains any design/visual work, the visual slice is applied by an `opus` sub-agent while purely non-visual slices stay on `sonnet`. See **Visual-Aware Apply Split** under Sub-Agent Context Protocol for the split mechanism.


### Sub-Agent Launch Pattern

ALL sub-agent launch prompts that involve reading, writing, or reviewing code MUST include the matching skill **paths** from the skill registry. Follow the **Skill Resolver Protocol** (`~/.codex/skills/_shared/skill-resolver.md`).

The orchestrator resolves skills from the registry ONCE (at session start or first delegation), caches the index, and injects matching skill paths into each sub-agent's prompt. Also reads the Model Assignments table once per session, caches `phase -> alias`, includes that alias in every Agent tool call via `model`.

Orchestrator skill resolution (do once per session):
1. `mem_search(query: "skill-registry", project: "{project}")` -> `mem_get_observation(id)` for full registry content
2. Fallback: read `.agent/skill-registry.md` if engram not available
3. Cache the skill index (skill names, triggers, scopes, and exact `SKILL.md` paths)
4. If no registry exists, warn user and proceed without project-specific standards

For each sub-agent launch:
1. Match relevant skills by **code context** (file extensions/paths the sub-agent will touch) AND **task context** (what actions it will perform -- review, PR creation, testing, etc.) against the `Trigger / description` column
2. Pass matching `SKILL.md` paths into the sub-agent prompt under `## Skills to load before work`
3. Inject BEFORE the sub-agent's task-specific instructions; tell the sub-agent to read those exact files before acting

**Key rule**: pass skill paths, not rule text. Sub-agents read the exact `SKILL.md` files themselves -- the registry is an index, not a summary. This preserves author intent and is compaction-safe because each delegation re-reads the registry if the cache is lost.

### Skill Resolution Feedback

After every delegation that returns a result, check the `skill_resolution` field:
- `paths-injected` -> all good, skill paths were passed correctly
- `fallback-registry`, `fallback-path`, or `none` -> skill cache was lost (likely compaction). Re-read the registry immediately and pass matching skill paths in all subsequent delegations.

This is a self-correction mechanism. Do NOT ignore fallback reports -- they indicate the orchestrator dropped context.

### Mandatory Writing Skills

Comments and documentation are not freeform. Whenever you, or a sub-agent you launch, will write a comment (PR/issue/review comment, chat or async reply, support ticket, email) or any documentation (README, RFC, guide, onboarding, architecture doc, PR description), you MUST load the relevant writing skill:

- Comments -> `comment-writer`
- Documentation -> `cognitive-doc-design`

This is not optional and is independent of registry matching: if the activity is writing a comment or a doc, the corresponding skill applies even if the registry returned no match for "comment" or "doc".

Applies in BOTH modes:
- **Delegating**: include the matching `SKILL.md` path in the sub-agent prompt under `## Skills to load before work`.
- **Writing directly (no sub-agent)**: YOU must read the matching `SKILL.md` yourself BEFORE drafting a single line. Self-check before any comment/doc output: "Did I load the writing skill this turn? If no, STOP and load it now." Do not rely on prior session memory of the skill -- read the file in the current turn.

Also pass the destination context (target repo/thread/channel and its primary language) so the writer applies the correct language -- write in the destination's language, not the chat language: English when the destination is primarily English, even if the user is talking to you in Spanish.

### Code Comment Hygiene

Code comments are not freeform either. Default to NO inline comments. Add one only when the WHY is non-obvious: a hidden constraint, a subtle invariant, a workaround for a specific bug, or behavior that would surprise a reader. If deleting the comment would not confuse a future reader, do not write it. Function-level documentation (intent, invariants, assumptions, side effects) is allowed and preferred over inline statement comments. Never write comments that restate what the code does, and never reference the current task, fix, PR, or ticket.

This applies whether you write code inline or delegate it. The executor sub-agents are self-sufficient and do NOT load CLAUDE.md/AGENTS.md, so they will not follow this rule unless you state it in the sub-agent prompt. When delegating any code-writing task, include this rule.

### Sub-Agent Context Protocol

Sub-agents get a fresh context with NO memory. The orchestrator controls context access.

#### Non-SDD Tasks (general delegation)

- Read context: orchestrator searches engram (`mem_search`) for relevant prior context and passes it in the sub-agent prompt. Sub-agent does NOT search engram itself.
- Write context: sub-agent MUST save significant discoveries, decisions, or bug fixes to engram via `mem_save` before returning. Sub-agent has full detail -- save before returning, not after.
- Always add to sub-agent prompt: `"If you make important discoveries, decisions, or fix bugs, save them to engram via mem_save with project: '{project}'."`
- Skills: orchestrator matches the registry and passes the matching `SKILL.md` paths under `## Skills to load before work` in the sub-agent prompt. Sub-agents read those exact files themselves; they do NOT rediscover the registry.

#### SDD Phases

Each phase has explicit read/write rules:

| Phase | Reads | Writes |
|-------|-------|--------|
| `sdd-explore` | nothing | `explore` |
| `sdd-propose` | exploration (optional) | `proposal` |
| `sdd-spec` | proposal (required) | `spec` |
| `sdd-design` | proposal (required) | `design` |
| `sdd-tasks` | spec + design (required) | `tasks` |
| `sdd-apply` | tasks + spec + design + **apply-progress (if exists)** | `apply-progress` |
| `sdd-verify` | spec + tasks + **apply-progress** | `verify-report` |
| `sdd-archive` | all artifacts | `archive-report` |

For phases with required dependencies, sub-agent reads directly from the backend -- orchestrator passes artifact references (topic keys or file paths), NOT content itself.

**Reuse-before-rediscover from the active artifact store (all phases -- SDD development AND testing).** The source of truth is whichever artifact store is active for the session (`hybrid` / `engram` / `openspec`) per Artifact Store Policy -- engram is ONE backend, not a hard requirement, and this rule must not assume engram is present. Beyond the required artifacts the orchestrator references, every phase sub-agent SHOULD open by reading relevant prior context from the active store and reuse what it finds rather than rediscover:

- Under `engram` or `hybrid`: `mem_search(query, project: "{project}")` for same-project prior work, and -- engram only -- `mem_search(query)` with NO project filter to discover analogous work in OTHER projects.
- Under `openspec`: read the relevant files under the `openspec/` tree (no cross-project discovery is available file-only).

Everything a phase produces is saved back to the active store. This rule is uniform -- the testing phases are NOT an exception; they follow the same artifact-store contract as the development phases.

#### Strict TDD Forwarding (MANDATORY)

When launching `sdd-apply` or `sdd-verify` sub-agents, the orchestrator MUST:

1. Search for testing capabilities: `mem_search(query: "sdd-init/{project}", project: "{project}")`
2. If the result contains `strict_tdd: true`:
   - Add to the sub-agent prompt: `"STRICT TDD MODE IS ACTIVE. Test runner: {test_command}. You MUST follow strict-tdd.md. Do NOT fall back to Standard Mode."`
   - This is NON-NEGOTIABLE. Do not rely on the sub-agent discovering this independently.
3. If the search fails or `strict_tdd` is not found, do NOT add the TDD instruction (sub-agent uses Standard Mode).

The orchestrator resolves TDD status ONCE per session (at first apply/verify launch) and caches it.

#### Apply-Progress Continuity (MANDATORY)

When launching `sdd-apply` for a continuation batch (not the first batch):

1. Search for existing apply-progress: `mem_search(query: "sdd/{change-name}/apply-progress", project: "{project}")`
2. If found, add to the sub-agent prompt: `"PREVIOUS APPLY-PROGRESS EXISTS at topic_key 'sdd/{change-name}/apply-progress'. You MUST read it first via mem_search + mem_get_observation, merge your new progress with the existing progress, and save the combined result. Do NOT overwrite -- MERGE."`
3. If not found (first batch), no special instruction needed.

This prevents progress loss across batches. The sub-agent is responsible for read-merge-write, but the orchestrator MUST tell it that previous progress exists.

#### Apply Scope Contract (MANDATORY)

Every `sdd-apply` launch — batched or not — MUST pin the executor to an exclusive scope. The executor does not read these orchestrator instructions; without an explicit scope in its launch prompt it will drift past the work you intended — implementing later batches, running unsupervised for hours, and reporting work it did not actually do.

When launching `sdd-apply`:

- Enumerate the EXACT assigned task IDs in the prompt (e.g. "Implement ONLY WU-0: T01-T04"). State explicitly: implement only these, then STOP and return; do NOT proceed to any other task, work unit, or batch.
- Pass the artifact-store mode, the Apply-Progress Continuity instruction, and the delivery/chain decision as usual.

After `sdd-apply` returns, BEFORE launching the next batch or trusting the report:

- Verify the executor stayed within the assigned scope against the REAL repo state (commits, changed files, the tasks artifact) — not the executor's prose. If the report is internally inconsistent or claims work the commits do not show, treat it as unreliable and reconcile from git/artifacts.
- If apply overran its scope (implemented beyond the assigned IDs), STOP. Do not launch further batches on top of an unsupervised overrun; surface the real state to the user and decide how to proceed.

Defense in depth: the executor has its own hard boundary (the `sdd-apply` skill's **Assigned Scope — HARD BOUNDARY**), and the orchestrator independently scopes each launch and checks the result.

#### Visual-Aware Apply Split (local policy, MANDATORY)

`sonnet` tends to produce weak visual/UI design. So when a change involves design work, the orchestrator isolates that work into its own `opus` apply.

Before launching the first `sdd-apply`, the orchestrator MUST inspect the tasks artifact and classify each task as **visual/design** or **non-visual**:

- **Visual/design**: UI layout, styling/CSS, component visual design, spacing/typography/color, responsive behavior, matching a design reference (Figma/Zeplin/screenshot), animations/transitions, or any task whose acceptance is "looks right".
- **Non-visual**: business logic, data layer, API/handlers, state, tests, config, build, infra — anything whose acceptance is "behaves right", independent of appearance.

If there are **no** visual/design tasks, run apply normally (single `sonnet` launch). Nothing changes.

If there **are** visual/design tasks, split apply into sequential slices that preserve the original task order and dependencies, alternating by class:

1. Non-visual tasks up to the first visual task → `sonnet`.
2. The contiguous visual/design tasks → `opus`.
3. The remaining non-visual tasks → `sonnet`.

This is the canonical 3-slice shape; if visual and non-visual tasks interleave more than once, produce more slices following the same alternation. The invariant is absolute: **every slice that contains design/visual work runs on `opus`; every purely non-visual slice runs on `sonnet`.** Collapse empty slices (e.g. when the change opens with visual work, slice 1 is empty — start at the `opus` slice).

Each slice is an ordinary `sdd-apply` launch and MUST follow the **Apply-Progress Continuity** protocol above: every slice after the first is a continuation batch, so tell it previous apply-progress exists and instruct it to read-merge-write. Forward Strict TDD to every slice as usual. Verify once, after the last slice.

#### Batched Apply-Verify Cycles (local policy)

Long or many-step changes are risky to apply in one shot: a single `sdd-apply` accumulates context until it loses track of what it is doing, and it can run a long time with no checkpoint or report. For such changes the orchestrator runs apply in ordered batches, each followed by its own verify and a concise report, so context stays fresh and problems surface early instead of compounding.

**Trigger (automatic).** Before launching the first `sdd-apply`, the orchestrator inspects the tasks artifact. The change is a batching candidate when it is large or multi-step — heuristics: more than ~8-10 implementation tasks, several distinct phases, or an estimated changed-line count above 400 (reuse the `Review Workload Forecast` from `sdd-tasks` when present). Small changes run as a single apply; nothing changes for them.

**Plan (orchestrator proposes, user confirms).** When the change qualifies, the orchestrator builds a batch plan — an ordered grouping of the tasks into self-contained batches (by phase or by logical cluster, each a coherent, independently verifiable unit) — and presents it for approval. In interactive mode it STOPS and shows the plan (batch count, the tasks in each, the boundaries) and waits for the user to approve or adjust before starting. In automatic mode it proceeds with its proposed plan without pausing, but still reports the plan and every per-batch result. The plan is not a fixed unit size — the orchestrator chooses boundaries that keep each batch coherent and bounded.

**Cycle.** For each batch in order:

1. Launch `sdd-apply` scoped to that batch only. Every batch after the first is a continuation batch, so the **Apply-Progress Continuity** protocol applies (read-merge-write the apply-progress).
2. Run `sdd-verify` scoped to that batch: validate the batch's implemented tasks against the relevant spec/design slice and the integrity of the work so far. Tasks belonging to later batches are `pending`, not failures.
3. Report a concise checkpoint to the user: what the batch did, the verify verdict, and what the next batch will do.
4. If the batch verify reports a CRITICAL issue, STOP and remediate that batch before starting the next. Do not let a broken batch compound into later ones.

Proceed to the next batch only after the current one's verify and report are done. After the last batch, run a final consolidated verify; archive only once all batches are complete and the **Task Completion Gate** passes.

**Composition.** This composes with the **Visual-Aware Apply Split** (a batch that contains design/visual tasks still routes that slice to `opus`; the model rule applies per slice within a batch) and with the cached `delivery_strategy` / `Review Workload Guard` (batch boundaries may align with chained-PR slices). Batching governs apply EXECUTION checkpoints; PR delivery strategy is a separate decision.

#### Engram Topic Key Format

| Artifact | Topic Key |
|----------|-----------|
| Project context | `sdd-init/{project}` |
| Exploration | `sdd/{change-name}/explore` |
| Proposal | `sdd/{change-name}/proposal` |
| Spec | `sdd/{change-name}/spec` |
| Design | `sdd/{change-name}/design` |
| Tasks | `sdd/{change-name}/tasks` |
| Apply progress | `sdd/{change-name}/apply-progress` |
| Verify report | `sdd/{change-name}/verify-report` |
| Archive report | `sdd/{change-name}/archive-report` |
| DAG state | `sdd/{change-name}/state` |

Sub-agents retrieve full content via two steps:
1. `mem_search(query: "{topic_key}", project: "{project}")` -> get observation ID
2. `mem_get_observation(id: {id})` -> full content (REQUIRED -- search results are truncated)

### State and Conventions

Convention files under the agent's global skills directory (global) or `.agent/skills/_shared/` (workspace): `engram-convention.md`, `persistence-contract.md`, `openspec-convention.md`, `gh-convention.md`.

### Recovery Rule

- `engram` -> `mem_search(...)` -> `mem_get_observation(...)`
- `openspec` -> read `openspec/changes/*/state.yaml`
- `none` -> state not persisted -- explain to user

## SDD Testing Workflow

Testing pipeline for feature validation. Supports browser, backend, API, and mixed testing modes. There is no archive phase in the testing pipeline — testing artifacts live in engram (plus the projected report file); there is nothing to merge or close out the way the development pipeline's `archive` does.

The orchestrator is responsible for surfacing this pipeline the same way it surfaces the SDD development pipeline — it must NOT stay silent and let a testing request fall through to an ad-hoc test run. Route by the intent behind the request, across three tiers. Classify the intent regardless of the language the user writes in, and respond in that same language — the descriptions below are intent categories, not phrases to match literally.

**Default bias: when in doubt, offer.** If you are unsure whether a request is testing intent at all, lean toward offering the pipeline rather than answering ad hoc. A missed offer is the failure mode to avoid — a non-technical user (PM, Design, QA) will not know the pipeline exists, will not type a slash command, and will not phrase things the "right" way. Treat any request that touches "is this working / does this look right / can you check this" as a candidate for the pipeline. The cost of an unwanted offer is one extra line the user ignores; the cost of a missed offer is the whole pipeline going unused.

**Tier 1 — Clear testing intent (do NOT ask WHICH pipeline; DO offer the depth).**
The user names a concrete feature, flow, card, screen, or endpoint to test, validate, or compare against a design. The intent is unambiguous, so do not ask "which pipeline" — it is the testing one. But do NOT silently assume the full ceremony and start acting: on the FIRST testing request of the session, surface the DEPTH choice once — the full SDD testing pipeline (explore → suites review → plan → run → report, persisted and reusable) versus a quick direct validation (a one-off check, no artifacts) — unless the user already named one (e.g. "/sdd-test", "usá el pipeline", or "solo fijate rápido"). Cache the choice for the session. Then proceed on the chosen path.

**Tier 2 — Proactive offer (do NOT silently skip — offer the pipeline).**
The user expresses an intent to validate, check, or QA something, but it is ambiguous whether they want the full pipeline or a quick one-off check (e.g. "does this work?", "make sure the new screen is OK before the demo"). Before doing anything, offer the two options the way the orchestrator offers SDD for a substantial code change: the full pipeline (explore → plan → run → report, which persists a reusable plan and report) versus a quick ad-hoc validation. Phrase the offer yourself, in the user's language. Wait for their choice; do NOT default to the ad-hoc path silently. If the user accepts but never named a concrete target, run the guided intake (see `/sdd-test` wizard) to collect what to test before launching `explore-testing`.

**Tier 3 — Bare execution (run directly, but mention the pipeline once).**
A bare test-execution request that names nothing to validate (e.g. "run the tests", "run the unit tests") runs the project's test command directly and reports the output. This is NOT a full-pipeline trigger. On the first such request in a session, note once that the feature-scoped testing pipeline exists; do not repeat it afterward.

When Tier 1 applies, or the user accepts a Tier 2 offer, enter the testing pipeline instead of the technical SDD pipeline. Whenever the user has not provided a concrete target (Tier 2 acceptance, or `/sdd-test` with no argument), do NOT guess what to test — run the guided intake described in the `/sdd-test` command to collect it in plain language, one question at a time.

#### No autonomous drift (MANDATORY)

The user must always know which path they are on and must not watch the orchestrator "go off and do things on its own." Two rules:

1. **Choose before acting.** Do NOT take any real action — driving the browser, launching an exploration, generating suites, running tests — before the user has picked the depth (full pipeline vs quick direct validation) and, for the pipeline, before the relevant human checkpoints (suites gate, and in interactive mode the per-phase pauses). Asking the setup questions is allowed; executing is not. If you catch yourself about to act without the user having chosen the path, STOP and offer first.
2. **Once on a path, stay on it.** If the user chose the full pipeline, follow its phases via their dedicated sub-agents (see "Agent binding") and its checkpoints — do not improvise an ad-hoc sequence of generic actions that bypasses the pipeline. If the user chose the quick direct validation, do THAT (a bounded one-off check) and report — do not silently expand it into an unscoped autonomous run. Switching paths mid-flow requires telling the user and getting agreement.

Generic agents (`Explore`, `general-purpose`, etc.) are perfectly fine for genuinely out-of-pipeline work and for the quick-direct path. The defect is not the agent type — it is bypassing or abandoning the chosen pipeline, or acting without the user having chosen at all.

### Source-of-truth-first (reuse before rediscover)

The testing pipeline is **engram-only by design**: its artifacts (`suites`, `explore`, `plan`, `run`, `report`) live in engram, and the testing sub-agents are wired with engram tools only. Entering the testing pipeline requires engram. The human-readable `report` is returned in full by `report-testing` so the orchestrator can surface it in chat (and optionally store it in Obsidian); it is NOT written into the repository tree.

This pipeline follows the same **reuse-before-rediscover** contract as the development phases (the common rule); only its available backend is narrower (engram). EVERY testing agent — the orchestrator AND all four sub-agents — MUST consult engram for relevant prior context BEFORE doing its work, not only the exact topic key of the current run. Search at two scopes:

- **Same project**: prior testing of this or related features (plans, runs, reports), known flaky areas, auth / test-data conventions, architecture and glossary, past decisions. Use `mem_search(query, project: "{project}")`.
- **Cross project**: analogous flows in OTHER projects (login, checkout, CRUD, forms, payments…) whose test cases or edge-cases became conventions worth reusing. Use `mem_search(query)` WITHOUT the project filter to discover them.

Everything an agent produces also goes back to engram. Nothing is re-derived if it already exists; nothing is lost.

This is the SAME reuse-before-rediscover rule the SDD development phases follow (see "Sub-Agent Context Protocol → Reuse-before-rediscover from the active artifact store") — testing differs only in that its store is engram-only (stated above), not in the reuse contract. The orchestrator still passes the required topic keys, and each sub-agent ADDITIONALLY runs same-project and cross-project discovery searches; the orchestrator MUST instruct each testing sub-agent to do so in its launch prompt.

### Test-Case Source & the test-suite-generator bridge

The "what to test" (user story + test cases) is produced UPSTREAM of `plan-testing` — by the user's first prompt, by `prd-engineering` (PRD / user story), or by the `test-suite-generator` skill (test suites / cases). It is NOT part of `plan-testing`. The user story is a precondition the orchestrator resolves; it is never written from scratch inside `plan-testing`.

The orchestrator KNOWS the `test-suite-generator` skill exists (it ships in the separate ai-hub assets — do NOT modify it) and OWNS persisting its output. `test-suite-generator` emits an inline Markdown test plan with no persistence of its own, so whenever it is used the orchestrator MUST capture that output and save it to engram under `testing/{project}/{feature}/suites`. Downstream phases read `suites` from engram.

#### Suites resolution gate (MANDATORY — runs after explore-testing, before plan-testing)

After `explore-testing` returns and BEFORE launching `plan-testing`, the orchestrator MUST resolve the test-case suites and get the user's sign-off. This is the human checkpoint that decides WHAT gets tested. Do NOT collapse it into `plan-testing` and do NOT skip it. The exact path depends on the cached **Test-case source** answer:

- **generate**: invoke the `test-suite-generator` skill now, feeding it the `sdd-explore-testing` output (already produced — the gate runs AFTER explore-testing) plus the spec / design reference. Do NOT launch a generic `Explore`/`general-purpose` agent to "understand the code first" — that work belongs to `sdd-explore-testing`; if its output is insufficient, extend or re-run that agent. `test-suite-generator` returns inline Markdown (suites grouped by area, each case with steps + expected result, plus the visual checklist when a design reference exists). Then:
  1. SHOW the generated suites to the user in chat.
  2. Ask the user to review: correct wording, add/remove cases, and — most importantly — mark **priority** (critical / normal / low) and which **edge cases** matter. This is a PRODUCT decision and is the user's checkpoint.
  3. Only after the user's explicit OK, persist the approved suites to `testing/{project}/{feature}/suites`.
- **conversation**: assemble the cases the user already gave in this thread into the suites shape, SHOW them back for confirmation (same review: priority + edge cases), then persist to `testing/{project}/{feature}/suites` after the user's OK.
- **engram**: load the existing `testing/{project}/{feature}/suites` (or an analogous one found via cross-project search), SHOW what was found, and ask whether to reuse as-is or adjust. Persist any adjustments before planning.

In all three paths the approved suites are persisted to engram BEFORE `plan-testing` launches. `plan-testing` then DERIVES the executable plan from the approved suites — it does NOT invent cases. In interactive execution mode, this gate is a hard pause; in automatic mode, still SHOW the suites and wait for the OK before persisting and planning — the suites review is a product checkpoint that automatic mode does NOT bypass.

### Testing Setup Questions (human-in-the-loop)

Everything is human-in-the-loop. On entering the testing pipeline for the first time in a session, STOP and ask the user the questions below before launching any sub-agent. Do NOT infer answers from prior conversation, available tools, or project structure — always ask explicitly.

Present all questions together in a single message so the user can answer in one reply. Do NOT proceed to `explore-testing` until all four answers are received.

1. **Test-case source** — where the cases come from:
   - **conversation** — the user already provided the story / cases in this thread.
   - **engram** — reuse an existing `testing/{project}/{feature}/suites` (or a prior plan, or an analogous case from another project found via cross-project search). Show what was found before reusing.
   - **generate** — run `test-suite-generator` now from the spec / PRD, then capture its output to `testing/{project}/{feature}/suites`.
   In all three cases the resolved cases end up persisted in engram BEFORE `plan-testing`.

2. **Execution engine / persona** — BLOCKING. The user MUST choose; there is no default:
   - **Sin código (Maestro visual/device)** (the `maestro` engine / `maestro (visual device)` persona) — the agent drives Android, iOS, or web/Chromium flows through Maestro MCP or CLI. It is device-first visual E2E, works with a real device, emulator, simulator, or supported web surface, and only persists `.maestro/**/*.yaml` flows when the user explicitly allows repo writes.
   - **Playwright (código)** (the `playwright` engine / `playwright (code)` persona) — the agent writes and runs Playwright spec files. Cross-browser, reproducible, leaves artifacts in the repo. Requires repo write access and Playwright installed.

   Present both options with a brief description. Do NOT pick one based on what tools are available. Wait for the user's explicit choice before proceeding. The chosen engine/persona is passed to `plan-testing` and `run-testing` and overrides any per-case engine assignment where applicable.

3. **Target environment** — local / staging / preview / production URL, or the app build / installed app to open when the run is mobile.
4. **Execution mode** — interactive / automatic. Default **interactive**, which pauses after EACH phase (explore → plan → run → report) to show that phase's result for approval before continuing.

### Feature Slug Resolution

The orchestrator resolves `{feature}` and `{project}` ONCE when entering the pipeline:

- **`feature_slug`**: Lowercase the input; replace spaces and non-alphanumeric characters with `-`; collapse consecutive `-` to one; trim leading/trailing `-`; truncate to 40 characters. Derive from the named feature, flow, card, or screen in the user's request (e.g. "card CU-1234" → `cu-1234`, "checkout flow" → `checkout-flow`, "onboarding screen" → `onboarding-screen`).
- **`project_slug`**: Derive from the target repo/project name (last path component of the working directory, or the repo name). Apply the same slug rules: lowercase, replace non-alphanumeric with `-`, collapse consecutive `-`, trim leading/trailing `-`, truncate to 40 characters.
- The orchestrator MUST pass BOTH `feature_slug` and `project_slug` explicitly in EVERY testing sub-agent prompt.
- Sub-agents MUST use the provided `feature_slug` and `project_slug` verbatim in all topic keys. Sub-agents MUST NOT derive their own slugs.

### Pipeline Graph

```
explore-testing → [resolve test-case suites + human review] → plan-testing → run-testing → report-testing
                   └── orchestrator-owned gate, NOT a sub-agent phase ──┘
```

The bracketed step is a MANDATORY gate, not an optional bridge. `plan-testing` MUST NOT be launched until the test-case suites exist in engram AND the user has reviewed them. See "Test-Case Source → Suites resolution gate" below. Skipping straight from `explore-testing` to `plan-testing` is a defect.

#### Agent binding (when you ARE running a pipeline phase)

Generic agents (`Explore`, `general-purpose`, `Plan`) are legitimate tools — this rule does NOT ban them. It binds the case where you are executing a phase of the testing pipeline: that phase runs on its OWN dedicated sub-agent, not on a generic one and not inline.

| Pipeline phase / step | Run it with |
|------|------|
| Investigate the feature/flow/code for testing | `sdd-explore-testing` sub-agent |
| Generate test-case suites from code/spec | the `test-suite-generator` skill, fed by the `sdd-explore-testing` output |
| Plan the executable test cases | `sdd-plan-testing` sub-agent |
| Execute the tests | `sdd-run-testing` sub-agent (fanned out into N runners) |
| Write the report | `sdd-report-testing` sub-agent |

Why it matters: a dedicated phase agent consults engram, writes its artifact under the right topic key, and returns the phase's result contract — a generic agent does none of that, so substituting one for a phase silently breaks engram persistence, topic keys, reuse-before-rediscover, and the downstream contract. The risk is highest with the common reflex "I need to understand the code before writing test cases" → that is `sdd-explore-testing`, not a generic `Explore`. The suites gate likewise does not run its own generic exploration; it reuses the `sdd-explore-testing` output (extend or re-run that agent if its output is thin).

This binding applies only while you are inside the testing pipeline. For the quick-direct path or any genuinely out-of-pipeline work, use whatever agent fits — including the generic ones.

### Phase Responsibilities

| Phase | Responsibility |
|-------|---------------|
| `explore-testing` | Consult engram first (same-project prior testing + cross-project analogous flows) and read the `suites` artifact if present; read codebase, existing Playwright and `.maestro/**/*.yaml` flows, TESTING_CONTEXT.md, Figma frames, ClickUp task — produce testing scope including likely testing modes; for browser/mobile cases, flag engine sensitivity (multi-browser or Safari coverage → `playwright`; device-first, native-app, or Chromium/web validation → `maestro`) |
| **suites gate** (orchestrator, not a sub-agent) | MANDATORY human-in-the-loop checkpoint between explore and plan. Resolve test-case suites per the cached source (generate / conversation / engram), SHOW them to the user, collect priority + edge-case decisions, and persist the APPROVED suites to `testing/{project}/{feature}/suites`. Never auto-skip — automatic mode does not bypass it. See "Test-Case Source → Suites resolution gate". |
| `plan-testing` | DERIVE the executable plan from the `suites` artifact when present (do NOT re-invent cases); otherwise generate from exploration. Structured test cases with IDs, priorities, mode per case, browser targets (browser mode only), engine per case (`playwright` / `maestro` for browser; `maestro` for mobile), visual-diff flags (browser/mobile mode with a design reference only) |
| `run-testing` | Delegated to the sub-agent for every engine. Branch on the session persona engine: `maestro (visual device)` → Maestro MCP/CLI against the approved Android / iOS / web target, no repo writes unless the user explicitly allows persisted `.maestro/**/*.yaml` flows; `playwright (code)` → Playwright CLI via Bash + spec files. Project test runner for backend; HTTP calls for api; mobile mode runs through Maestro — perform visual diff only when mode is browser or mobile and a design reference is available. **Read-only for application code: failures are recorded as findings, never fixed.** |
| `report-testing` | Produce human-readable summary — pass/fail table with Engine column for browser/mobile rows, evidence references (browser/device + screenshot/hierarchy when present), findings grouped by mode when mixed, follow-up items. This is the final phase of the testing pipeline. |

### Engram pre-flight guard (MANDATORY — blocking)

Run this BEFORE anything else in the testing pipeline (before `explore-testing`, before the setup checkpoints below). The testing pipeline is engram-only: every phase reads and writes engram. If engram is not reachable, the run will fail cryptically at the first `mem_save` mid-flow — unacceptable for a non-technical user.

1. Verify engram is reachable with a lightweight call (e.g. `mem_current_project` or a trivial `mem_search`).
2. If it responds → proceed.
3. If it is NOT available → STOP. Do NOT enter the pipeline. Tell the user plainly that engram (the memory the pipeline depends on) is not registered for this project, and how to fix it: re-run the installer, or `claude mcp add --scope project engram engram mcp`. Unlike the tool prerequisites below, this is a hard block — engram absence is not "best-effort continue".

### Prerequisites Check

Two checkpoints. Do NOT block the pipeline on missing prerequisites — warn and continue. Setup remains system-agnostic and user-guided: discover the current OS / toolchain first, do NOT assume a package manager or a pre-created device, and ask before any heavy install, SDK license acceptance, AVD / simulator creation, cloud provisioning, or repo file write. If two or more tool prerequisites are absent at once, ASK the user what they want to do before continuing: "Faltan algunas herramientas del pipeline. ¿Querés que corra `/setup-testing` para prepararlas ahora, o seguimos con lo que haya (best-effort)?"

**Checkpoint 1 — before launching `explore-testing` (universal, mode not yet known):**

| Prerequisite | How to check | Warning if absent |
|-------------|-------------|-------------------|
| `TESTING_SETUP.md` at repo root | `Read TESTING_SETUP.md` | "No TESTING_SETUP.md found. Run `/sdd-testing-context` first for better results. Continuing with best-effort." |
| Test credentials in env | Check env var names from TESTING_SETUP.md | "Env vars for test credentials not set. Tests requiring auth will fail." |

**Checkpoint 2 — after `plan-testing` returns (mode and engine are now known), before launching `run-testing`:**

| Mode | Engine | Prerequisite | How to check | Warning if absent |
|------|--------|-------------|-------------|-------------------|
| `browser` | `playwright` | Playwright installed | `npx playwright --version` | "Playwright not found. Run `/setup-testing` or install manually: `npm install -D @playwright/test`" |
| `browser` | `playwright` | Browser binaries | `npx playwright install --dry-run` | "Some browser binaries may be missing. Run `/setup-testing` or: `npx playwright install`" |
| `browser` | `maestro` | Maestro CLI | `maestro --version` | "Maestro CLI not found. Run `/setup-testing` or install Maestro before the run." |
| `browser` | `maestro` | Maestro MCP helpers | Check whether tools such as `list_devices` / `run` are available before delegating | "Maestro MCP helpers not detected. Continuing with CLI-only Maestro; live inspection helpers may be unavailable." |
| `browser` | `maestro` | Reachable Maestro web / device target | Prefer `list_devices`; otherwise confirm the Chromium/web target from `TESTING_SETUP.md` or the user | "No Maestro target was confirmed for the web run. Ask the user before provisioning a browser/device session." |
| `mobile` | `maestro` | Maestro CLI | `maestro --version` | "Maestro CLI not found. Run `/setup-testing` or install Maestro before the run." |
| `mobile` | `maestro` | Maestro MCP helpers | Check whether tools such as `list_devices` / `run` are available before delegating | "Maestro MCP helpers not detected. Continuing with CLI-only Maestro; live inspection helpers may be unavailable." |
| `mobile` | `maestro` | Device / simulator availability | Prefer `list_devices`; otherwise `adb devices`, `xcrun simctl list devices`, or a user-approved cloud target | "No eligible device/simulator found. Ask before creating an AVD/simulator or using a cloud device." |
| `mobile` | `maestro` | `appId`, bundle ID, or launchable app target | Read `TESTING_SETUP.md` or the plan for the installed app ID, app path, or launch command | "Mobile Maestro run has no app target. Provide the installed app identifier or build artifact before running." |
| `backend` | — | Project test runner reachable | Run the test command with `--help` or `--version`, or check PATH for `pytest`/`go`/etc. | "Test runner not found. Check TESTING_SETUP.md for the correct command." |
| `api` | — | `curl` or project-defined HTTP runner available | `curl --version` | "curl not found. HTTP-based tests will fail." |

Only check the rows matching modes and engines that appear in the test plan. Skip rows for modes not present.

### Engram Topic Key Format (Testing)

| Artifact | Topic Key |
|----------|-----------|
| Test-case suites (upstream / test-suite-generator) | `testing/{project}/{feature}/suites` |
| Exploration | `testing/{project}/{feature}/explore` |
| Plan | `testing/{project}/{feature}/plan` |
| Run shard (one parallel runner / unit) | `testing/{project}/{feature}/run/{session-id}/{unit-id}` |
| Run (consolidated session, orchestrator merges shards) | `testing/{project}/{feature}/run/{session-id}` |
| Run (latest pointer, orchestrator-owned) | `testing/{project}/{feature}/run/latest` |
| Report | `testing/{project}/{feature}/report` |

Session IDs use timestamp format `YYYYMMDD-HHMM`. The orchestrator generates ONE session ID per run and passes it to every parallel shard.

### Reads and Writes Table

| Phase | Reads | Writes |
|-------|-------|--------|
| `explore-testing` | engram discovery (same + cross project), `testing/{project}/{feature}/suites` (if present), TESTING_CONTEXT.md (product context), TESTING_SETUP.md (tech setup), ARCHITECTURE.md, GLOSSARY.md (optional), codebase files | `testing/{project}/{feature}/explore` |
| `plan-testing` | `testing/{project}/{feature}/explore` (required), `testing/{project}/{feature}/suites` (if present — derive from it), engram discovery, TESTING_CONTEXT.md, TESTING_SETUP.md | `testing/{project}/{feature}/plan` |
| `run-testing` (per parallel runner) | its assigned execution unit from `testing/{project}/{feature}/plan` (required), engram discovery (prior runs / flaky), TESTING_SETUP.md (required — warn if absent), TESTING_CONTEXT.md (optional — informs pass/fail interpretation) | `testing/{project}/{feature}/run/{session-id}/{unit-id}` (shard), or the consolidated `run/{session-id}` if it is the only runner (never `run/latest`); Playwright spec files (playwright persona only); optional `.maestro/**/*.yaml` flows (Maestro persona only, and only when the user explicitly allowed persisted flows) |
| orchestrator (after runners return) | all shard observations | merges into `testing/{project}/{feature}/run/{session-id}` and `testing/{project}/{feature}/run/latest` |
| `report-testing` | `testing/{project}/{feature}/run/latest` (required), `testing/{project}/{feature}/plan` (required), prior reports (engram discovery) | `testing/{project}/{feature}/report` (full report returned in result; surfaced in chat, optionally stored in Obsidian — never written into the repo tree) |

For phases with required dependencies, pass artifact references (topic keys) to sub-agents —
NOT content. Sub-agents retrieve full content via `mem_search` + `mem_get_observation`.

### Question Rule

The orchestrator asks the user for PRODUCT decisions. It does NOT ask for TECHNICAL decisions.

**Ask the user (PRODUCT decisions):**

- Where do the test cases come from? (this conversation / engram / generate now with `test-suite-generator`)
- Which execution engine / persona? (`maestro (visual device)` / `maestro` for device-first Android / iOS / web validation, or `playwright (code)` for reproducible cross-browser coverage)
- Which test cases are `critical` vs `low` priority?
- Which browsers or device surfaces must be covered (e.g. Safari/WebKit, Android, iOS, or Chromium via Maestro)?
- Which edge cases matter for this feature (e.g. empty state, error state)?
- Is `mobile` mode required for this run, or is browser-only enough?
- If Maestro is chosen, should flows stay ephemeral or may the runner persist `.maestro/**/*.yaml` files in the repo?
- Which environment to target (local / staging / preview / installed app build)?

**Do NOT ask the user (TECHNICAL decisions):**

- Which CSS selector, Maestro locator, or Playwright locator to use
- Which timeout value to set
- Whether to use `getByRole`, a test id, or a Maestro hierarchy selector
- Which Playwright project or Maestro flag to apply

When in doubt about a technical decision, choose the approach that follows existing project
conventions and note it in the run artifact.

### Surfacing results and decisions to the user (progressive, human-readable)

Persisting an artifact to engram is NOT communicating with the user. Every time the orchestrator pauses a phase (interactive mode) or asks the user to decide something, it MUST first surface a concise, human-readable digest IN CHAT. Do NOT rely on the user opening engram, and do NOT defer everything to the final `report-testing` phase. The report is the full picture at the end; intermediate digests are what let the user steer along the way.

**Phase digests.** When a phase returns and the orchestrator pauses, show a short readable summary of what that phase produced — not just the topic key and a one-line `executive_summary`. The testing sub-agents return a dedicated digest field for this; surface it to the user verbatim (lightly reformatted if needed), do not reconstruct it from the summary:
- `explore-testing` → `explore_digest`: feature + where it lives, applicable modes, in/out of scope, design reference availability, engine hints.
- `plan-testing` → `plan_digest`: in-scope cases grouped by area (ID, title, priority, mode, visual-diff flag), plus deferred cases and why. The user should see WHAT will be tested before approving the run.
- `run-testing` → `run_digest`: headline pass/fail/skip/error counts, then the failures (one plain-language line each) and any skips with their reason.

Lead with the headline, then the list. If a sub-agent omits its digest field, ask it to provide one rather than dumping the raw artifact on the user.

**Self-contained decisions (MANDATORY).** Never ask the user to confirm or choose something they cannot evaluate from the question alone. When a decision references specific test cases (priority, skip-vs-force, which edge cases matter, mobile viewport, etc.), the question MUST include, for each referenced case:
- its ID and title,
- one line on what it validates,
- what each option means and its consequence (e.g. "Skip → no coverage for the empty-PR message this run; Force → seed a light set to guarantee the no-PR state, slower but real coverage").

A bare `"SUM-03: ¿qué hago?"` with options the user can only guess at is a defect. If the user would have to open engram or wait for the report to understand the question, the orchestrator has not surfaced enough — expand the question first.

**Progressive disclosure.** Keep digests tight (recognition over recall: tables and short lists, not walls of prose). Push full detail — selectors, stack traces, raw run logs — to the artifacts and the final report, never into a mid-flight decision prompt. The digest carries exactly enough to decide; no more.

### Execution Policy

#### run-testing is always delegated (read first)

`run-testing` is DELEGATED to the `sdd-run-testing` sub-agent for EVERY engine, with no exception. The orchestrator stays thin and never executes the run itself — that is the whole point of the sub-agent architecture, and it holds for the no-code and code-driven paths equally.

- **`maestro` / `maestro (visual device)` → delegate.** The sub-agent drives Android, iOS, or web/Chromium flows through Maestro. Prefer Maestro MCP tools (`list_devices`, `inspect_screen`, `take_screenshot`, `run`, `cheat_sheet`, `open_maestro_viewer`) when available; otherwise fall back to Maestro CLI (`maestro test`, `maestro hierarchy`) where possible. Do NOT edit app source. Persist `.maestro/**/*.yaml` only when the user explicitly allows repo-backed flows; otherwise keep YAML inline / ephemeral.
- **`playwright` / `backend` / `api` → delegate.** Bash-driven (`playwright test`, the project test runner, `curl`) plus engram.
- **`mixed`**: delegated as parallel execution units (see below), one runner per unit, results merged.

There is NO default engine. The engine/persona is a blocking product choice (see Testing Setup Questions). On this agent surface, `maestro (visual device)` means the Maestro visual/device flow, while `playwright (code)` is the reproducible cross-browser suite option.

#### Parallel execution — fan out N runners (read second)

run-testing is NOT a single runner by default. Most test cases are independent (non-blocking), so the orchestrator fans out **N `sdd-run-testing` sub-agents in parallel**, one per execution unit, and merges their results. A single runner is only correct when the plan reduces to one unit.

**Execution units come from the plan.** `plan-testing` partitions the cases into execution units (see its output contract):
- An **independent case** is its own unit — parallelizable with every other independent unit.
- A **dependency chain** (case A writes data that case B reads, e.g. `CAT-05` seeds a fixture for `CAT-06`) is ONE unit that runs its cases sequentially inside a single runner. Never split a chain across runners.

**The orchestrator launches one runner per unit, concurrently**, passing each runner only its unit's cases. Bound the fan-out by:
1. **Data dependencies** — already encapsulated: chains are single units, so ordering is preserved within a runner.
2. **Shared mutable state** — two units that write the SAME data (same record, same user's state) would collide if concurrent. `plan-testing` flags these as conflicting; the orchestrator serializes conflicting units (or relies on isolated per-unit test data when the plan says it is available). Read-only cases never conflict.
3. **Engine concurrency** — `playwright` / `backend` / `api` units parallelize freely (isolated processes / browser contexts). `maestro` / `live` units are bounded by how many devices, emulators, simulators, or web targets are actually available and by whether the user wants to watch the run. Do not auto-create or auto-provision extra targets without asking first.
4. **A sane concurrency cap** — do not launch dozens at once; batch to a reasonable number of concurrent runners.

**Per-unit model.** Apply the conditional model per runner: a unit whose cases include `visual diff: yes` launches with `opus`; purely mechanical units launch with `sonnet`. So visual units get the strong vision model without paying for it on the rest.

**Result merge (orchestrator-owned).** Each runner writes its own shard observation under `testing/{project}/{feature}/run/{session-id}/{unit-id}` (a sole runner writes the consolidated `testing/{project}/{feature}/run/{session-id}` directly) and returns its `run_digest`. The orchestrator MERGES all shards into the consolidated `testing/{project}/{feature}/run/{session-id}` and ALWAYS writes `testing/{project}/{feature}/run/latest` itself — even for a single runner; runners never write `run/latest`. The `run/latest` content MUST include the top-level fields `session_id: "{session-id}"` and `session_topic_key: "testing/{project}/{feature}/run/{session-id}"`, so `report-testing` can read the `session_id` and resolve one latest run. Surface a combined run digest to the user.

The session **persona engine** (chosen in Testing Setup Questions) takes precedence for browser/mobile cases: `maestro (visual device)` forces `maestro` for browser cases the user chose to validate through Chromium/web and for ALL `mobile` cases; `playwright (code)` forces `playwright` for browser cases. Only when no persona was set does the per-case `engine` determined during `plan-testing` apply. With that precedence in mind, automated test runs dispatch based on the `mode` and, for UI cases, the resolved `engine`:

- **`browser`**: Two engines are available. The plan assigns one per test case.

  - **`engine: playwright`**: Run via Playwright CLI via Bash, headless or headed. Cross-browser across Chromium / Firefox / WebKit as specified in the test plan. Use for: multiple browsers required, regression suites, repeatable runs, anything needing visual diff across browsers.

  - **`engine: maestro`**: Run web/Chromium or device-proxy flows through Maestro MCP or CLI. Use for: device-first visual E2E, the same flow needing to span mobile + web, or a no-code browser run where Chromium coverage is sufficient. Evidence comes from Maestro screenshots / hierarchy, not Playwright spec files.

  Browser inspection helpers (Playwright MCP or Maestro helpers) may be used for DOM or screen inspection, but they do not replace the chosen execution engine.

- **`mobile`**: `engine: maestro` only. Drive Android / iOS flows through Maestro MCP or CLI. Requires a reachable device/emulator/simulator (or approved cloud target) plus a known `appId`, bundle ID, app path, or launch target. Prefer inline YAML while refining a run; only write `.maestro/**/*.yaml` when the user explicitly allows persisted flows.

- **`backend`**: Invoke the project's test runner via Bash. The command and runner are read from
  `TESTING_SETUP.md` when present; otherwise detect from the repo:
  - `package.json` scripts (`npm test`, `npx vitest`, `npx jest`)
  If detection fails, report which signals were checked and mark as `partial`.

- **`api`**: HTTP calls via `curl` via Bash, or a project-defined runner specified in
  `TESTING_SETUP.md` (e.g. a Postman collection runner, `supertest` script, or `httpie`).

- **`mixed`**: Dispatch each subset to its respective execution path within the same run session.
  Collect and label results per mode before saving the run artifact.

### Visual Diff Policy

Applies only when `mode` includes `browser` or `mobile` AND a design reference is associated with the screen under test. Otherwise skipped.

A design reference can be any of: a Figma frame URL or node ID, a Zeplin link, an Adobe XD share link, a Sketch Cloud URL, a screenshot file, or any URL that renders the intended design. The agent uses whatever is available — Figma MCP when the reference is a Figma URL and the MCP is connected, direct visual inspection for screenshots or rendered URLs, or a manual description when no tool can extract specs automatically.

Visual comparison uses a **structured checklist**, not pixel diff.

The checklist extracts typography, color, spacing, and layout specs from the design reference and verifies them against computed DOM styles or device-observed UI properties. Pixel diff screenshots are informative artifacts for human review, NOT a pass/fail criterion. Screenshot persistence is persona-aware: `playwright (code)` saves them under a temporary directory outside the repository tree (e.g. `/tmp/sdd-testing/{feature}/screenshots/`); `maestro (visual device)` / `maestro` prefers Maestro screenshots and hierarchy captures attached to the run artifact or saved to a temporary directory outside the repository tree. `.maestro/**/*.yaml` is the only repo-backed Maestro artifact, and only when the user explicitly permits persisted flows. Screenshots are never written into the repository tree.

See `~/.codex/skills/visual-diff/SKILL.md` for the full methodology.

### Re-runs

A repeat request for an already-tested feature ("probá de nuevo", "corré de nuevo los tests de X", "run it again"):

1. Reuse the existing `testing/{project}/{feature}/plan` topic key — skip `explore-testing` and `plan-testing`.
2. Generate a NEW session ID (timestamp `YYYYMMDD-HHMM`).
3. Launch the run with the same parallel fan-out (N runners over the plan's execution units) and the new session ID; the orchestrator merges the shards and overwrites `run/latest` (with the new `session_id`).
4. Run `report-testing` as normal, using the new session ID for the output filename.

If the user asks to re-plan (e.g. "re-plan the tests", "scope changed") or if the feature has changed significantly since the last explore, start from `explore-testing` instead.

### What This Pipeline Does NOT Do

- Does not fix failing tests or application code — failures are findings for the report, not tasks for the orchestrator.
- Does not file bug reports or tickets automatically — the report produces follow-up items; a human decides what to file.

#### Failures are reported, never remediated or blocking (MANDATORY)

The pipeline user is often a QA / PM / Design person, not a developer. Fixing failing code is the DEV's responsibility, not theirs. So when a test fails:

- **Never offer to fix it.** Do NOT say "¿querés que lo arregle?", do NOT propose a code change, a diff, or a debugging session. The orchestrator's job ends at reporting the failure clearly.
- **Never block the flow on a failure.** A failed case does not halt the pipeline or gate the next phase. Record it, continue with the remaining cases, and always proceed to `report-testing`. The user is never left stuck because something failed.
- **Never make the user responsible for a dev decision.** Do not ask the non-technical user how to fix, whether to change code, or to triage a stack trace. Surface the failure in plain language in the report and stop there; what to do about it is a separate, dev-owned step outside this pipeline.

The only failure-driven action the orchestrator may take is a re-run AFTER a human (the dev) reports they fixed something — and only if the user asks for it. It never initiates remediation itself.

<!-- /hk-specflow:sdd-testing -->
