## SDD Workflow (Spec-Driven Development)

SDD is the structured planning layer for substantial changes. This file is the lazy-loaded Claude Code workflow surface; read it before handling `/sdd-*`, SDD meta-commands, SDD/Judgment-Day phase delegation, or SDD continuation/routing.

### Artifact Store Policy

- `engram` — default when available; persistent memory across sessions.
- `openspec` — file-based artifacts; use only when the user explicitly requests it or a change already exists there.
- `hybrid` — both backends; useful for team-shareable files plus cross-session recovery.
- `none` — return results inline only; recommend enabling engram or openspec.

### Commands

Skills and slash commands:

- `/sdd-init` → initialize SDD context; detects stack and testing capabilities.
- `/sdd-explore <topic>` → investigate an idea; no implementation.
- `/sdd-status [change]` → read-only structured status.
- `/sdd-apply [change]` → implement pending tasks in batches.
- `/sdd-verify [change]` → validate implementation against specs/tasks.
- `/sdd-archive [change]` → close a completed change.
- `/sdd-onboard` → guided end-to-end walkthrough.

Meta-commands are handled by the orchestrator directly and do not appear in autocomplete:

- `/sdd-new <change>` → run exploration then proposal.
- `/sdd-continue [change]` → run the next dependency-ready phase.
- `/sdd-ff <name>` → fast-forward proposal → specs → design → tasks.

### Native SDD Dispatcher Guard

Before routing, continuing, applying, verifying, or archiving an SDD change, first determine this session's artifact store. The native dispatcher (`gentle-ai sdd-continue [change] --cwd <repo>` or `gentle-ai sdd-status [change] --cwd <repo> --json --instructions`) reads only OpenSpec file artifacts and always emits `artifactStore: openspec`; it cannot observe Engram-backed changes.

- For `engram`, do NOT invoke the dispatcher. Resolve status from Engram topic keys with `mem_search` followed by `mem_get_observation`.
- For `openspec` or `hybrid`, use the dispatcher when available and treat its JSON as authoritative over prompt inference.
- Route only by structured `nextRecommended`, dependency states, and `blockedReasons`; never infer from free text.
- If blocked, stop and report the blocker. Do not proceed to apply, archive, or terminal work.

### SDD Session Preflight (HARD GATE)

Before executing ANY SDD command or natural-language SDD request, ensure this session has an explicit `SDD Session Preflight` decision block.

This applies to `/sdd-new`, `/sdd-ff`, `/sdd-continue`, `/sdd-explore`, `/sdd-status`, `/sdd-apply`, `/sdd-verify`, `/sdd-archive`, and natural-language equivalents such as "use SDD to add dark mode" / "do it with SDD".

Required preflight choices:

1. **Execution mode**: `interactive` or `auto`.
2. **Artifact store**: `openspec`, `engram`, or `hybrid` when Engram is callable. If Engram is unavailable, offer only file/inline-safe choices.
3. **Chained PR strategy**: the canonical `delivery_strategy` — `ask-on-risk`, `auto-chain`, `single-pr`, or `exception-ok`. The preflight menu offers the first three; `exception-ok` is reachable only when the user explicitly accepts `size:exception`.
4. **Review budget**: maximum changed lines before stopping for reviewer-burden approval.

User-facing preflight question format:

Use Agens choice transport for SDD Session Preflight only when it is available in the current interactive runtime and all four groups are exactly representable. While that native route is usable, do NOT render a duplicate plain-chat menu. If the tool is unavailable, denied, the runtime is noninteractive, or the prompt is unrepresentable, follow the Lossless Blocking Prompts fallback in the orchestrator rule and STOP.

When the native route is representable, ask all four preflight groups in one single `grouped choice prompt` tool call so Claude Code can render the groups as one interactive prompt. Do NOT run this as a sequential wizard. Do NOT issue four separate `grouped choice prompt` tool calls.

The single `grouped choice prompt` tool call must contain these four localized groups in this order:

1. Pace: Interactive, Automatic.
2. Artifacts: OpenSpec, Engram, Both.
3. PRs: Ask me, Single PR, Auto.
4. Review: 400 lines, 800 lines, Other.

Match the user's current language and active persona for question labels and descriptions. Treat the preflight UI as direct orchestrator conversation, not as a generated technical artifact. Technical artifacts still default to English, but this UI follows the user's conversation language/persona. Do NOT mix languages inside one grouped question.

Do NOT show option codes in the interactive UI. Do NOT show canonical values or other internal values in the interactive UI labels or descriptions.

After the single grouped `grouped choice prompt` tool call returns, map the selected human labels to canonical values internally. Do not reveal the canonical values in the UI.

If Other is selected for review budget, ask one follow-up question for the numeric budget.

Only after all four preflight choices are collected, summarize them as the `SDD Session Preflight` decision block and continue with the SDD init guard/requested phase.

Map answers to canonical values:

- Pace: Interactive -> `interactive`; Automatic -> `auto`.
- Artifacts: OpenSpec -> `openspec`; Engram -> `engram`; Both -> `hybrid`.
- PRs: Ask me -> `ask-on-risk`; Single PR -> `single-pr`; Auto -> `auto-chain`.
- Review: 400 lines -> `review_budget_lines: 400`; 800 lines -> `review_budget_lines: 800`; Other -> ask one follow-up for the number.

The PR canonical values are exactly the `delivery_strategy` domain `sdd-tasks` and `sdd-apply` accept; never emit a value outside it. The preflight offers no separate chained option because `delivery_strategy` is only consulted once the tasks forecast flags review-budget risk: below that line there is nothing to chain, and above it `Auto` already resolves to `auto-chain` without asking again.

Hard gate rules:

- `openspec/config.yaml`, existing SDD artifacts, previous `sdd-init` results, or installed SDD assets do NOT satisfy session preflight.
- If the session has no preflight block, ask the single grouped `grouped choice prompt` preflight above. Do not run init, delegate phases, edit files, or apply tasks until all four choices are collected.
- Cache the choices for this session and include them in later phase prompts.
- If the user explicitly provided all four choices in the current conversation, summarize them as the session preflight block and continue.

### SDD Entry Routing (MANDATORY)

For a new product/code change request that says to use SDD, start at preflight -> init guard -> explore/proposal (`/sdd-new` equivalent). Never launch `sdd-apply` just because the user asked to implement a feature.

Only launch `sdd-apply` when all are true:

1. Session preflight is complete.
2. The active change has existing spec, design, and tasks artifacts.
3. The user explicitly asked to apply/continue implementation, or the prior SDD planning phase completed and the orchestrator has passed the review workload guard.

If any dependency is missing, STOP and propose `/sdd-new` or `/sdd-ff`; do not implement.

### SDD Init Guard (MANDATORY)

Before executing any SDD command or meta-command, check whether `sdd-init` has run for this project:

1. Search Engram: `mem_search(query: "sdd-init/{project}", project: "{project}")`.
2. If found, proceed normally.
3. If not found, run `sdd-init` first, then continue with the requested command.

This ensures testing capabilities, Strict TDD mode, and project context are available to later phases.

### Execution Mode

This is collected by `SDD Session Preflight`. If missing, enforce the hard gate before any phase work. Cache the collected mode for the session:

- **Automatic** (`auto`): phases run back-to-back without pausing, but the orchestrator gatekeeper validates after each phase before launching the next.
- **Interactive** (`interactive`): after each phase, show a concise summary and ask whether to adjust or continue.

If the user doesn't specify, default to **Automatic**. After scope approval, expect zero further prompts on the happy path and at most one actionable prompt per recoverable failure; the gatekeeper summarizes phase progress instead of interrupting except on a second consecutive gate failure or a genuine scope/product decision. Interactive approval is phase-scoped; words like "continue", "dale", or "go on" approve only the immediate next phase.

Before the `sdd-propose` phase in interactive mode, offer the user a proposal question round focused on business/product understanding, business problem, business rules, outcomes, implications and impact, edge cases, scope boundaries, non-goals, constraints, and product tradeoffs. Do not ask about test commands, PR shape, changed-line budget, or other harness mechanics unless the user explicitly asks.

### Automatic Mode Gatekeeper (MANDATORY)

In Automatic mode, the orchestrator validates every delegated phase result before launching the next phase. The gatekeeper runs after every phase and before launching the next sub-agent.

Gate checks:

- **Contract conformance:** returned `status`, `executive_summary`, `artifacts`, `next_recommended`, `risks`, and `skill_resolution`; status is not partial/failed/blocked.
- **Artifact existence:** declared artifact is readable in the active backend.
- **No hallucination:** claimed files, symbols, commands, and artifacts exist.
- **No drift from inputs:** proposal/spec/design/tasks/apply outputs stay consistent with their dependencies.
- **Routing coherence:** `next_recommended` follows the dependency graph and no unaddressed CRITICAL risk remains.

Hybrid validation:

- Inline for low-risk phases: `sdd-explore`, `sdd-spec`, `sdd-tasks`, `sdd-archive`.
- Fresh-context phase-contract validator for `sdd-design` and `sdd-apply`: validate only the phase artifact against its inputs. This is not adversarial implementation review, inspects no code diff, and creates no 4R/Judgment-Day budget.
- Escalate to fresh-context review when an inline gate smells wrong.

On gate failure, re-run the same phase exactly once with specific corrective feedback. If the second result fails, STOP the automatic chain and report; do not advance dependent phases.

### Native Runtime Attempt Authority (MANDATORY)

Use the provider-owned Git-common-dir runtime ledger for every runtime-bearing `sdd-apply`, `sdd-verify`, or remediation continuation. It is the single attempt/budget authority for both OpenSpec and Engram; never persist caller-authored counters in OpenSpec files, Engram topics, prompts, or Pi state.

1. Before an actor or harness launch, call `gentle-ai sdd-attempt acquire --cwd <repo> --change <change> --request-id <id> --work-unit <label> --evidence-goal <goal> --max-attempts <count> --max-changed-lines <count>`.
   - Exception: when this launch is a phase actor started BY a parent that already ran this exact acquire and got `state: proceed`, do not acquire blind — pass the parent's returned token as `--token <token>` on the actor's own acquire call. A matching token proves the actor is continuing that SAME attempt and returns `proceed` with zero ledger mutation; acquiring without it collides with the parent's own active attempt and deadlocks on `blocked: active_attempt` (#2291).
2. Launch only when acquire returns `state: proceed`, and retain its opaque `token`. `blocked` or `complete` stops the launch.
3. After the external run, call `gentle-ai sdd-attempt settle --cwd <repo> --change <change> --token <token> --request-id <settle-id> ...` with a request ID distinct from the acquire operation's request ID, outcome, and bounded evidence. Reuse each operation's own ID only for its idempotent replay. Settle derives native binding/remediation inputs; pass `--successor-lineage` only for a distinct approved successor, otherwise the bound lineage remains its own successor.
4. Route only from settle's `proceed`, `blocked`, or `complete` state. Full `status|begin|finish|reset` operations are diagnostic/compatibility surfaces; reset requires an explicit maintainer scope decision and is never automatic.

### Artifact Store Mode

This is collected by `SDD Session Preflight`. If missing, enforce the hard gate before any phase work. Cache the collected store (`engram`, `openspec`, `hybrid`, or `none`) for the session. If unspecified, default to `engram` when Engram is available; otherwise use `none` and explain the persistence limitation.

Pass the artifact store mode to every SDD phase agent.

### Delivery Strategy

On the first SDD chain request in a session, ask once for delivery strategy and cache it:

- `ask-on-risk` — default; ask only when the tasks forecast detects review-budget risk.
- `auto-chain` — automatically split into chained/stacked PR slices when needed.
- `single-pr` — proceed as one PR only if the size is within budget.
- `exception-ok` — user accepts `size:exception` when over budget. The preflight menu cannot select this; it is reached only when the user explicitly accepts `size:exception`, either up front or when `ask-on-risk` stops to ask.

These four are the whole domain. Pass `delivery_strategy` to `sdd-tasks` and `sdd-apply`.

### Chain Strategy

When delivery planning yields chained PRs, ask once for chain strategy and cache it:

- `stacked-to-main` — each PR targets the previous PR branch or main in sequence.
- `feature-branch-chain` — PR #1 targets the tracker branch; child PRs target the immediate previous PR branch; only the tracker merges to main.

When chained PRs are selected, treat `chained-pr` (registry skill `gentle-ai-chained-pr`) as a required skill match. Resolve and forward it by registry path to `sdd-tasks` and `sdd-apply`; do not hardcode its path.

Pass it as `chain_strategy` to `sdd-tasks` and `sdd-apply` prompts alongside `delivery_strategy`.

### Dependency Graph

```text
proposal -> specs --> tasks -> apply -> verify -> archive
             ^
             |
           design
```

### Result Contract

Every SDD phase returns: `status`, `executive_summary`, `artifacts`, `next_recommended`, `risks`, and `skill_resolution`.

### Review Workload Guard (MANDATORY)

After `sdd-tasks` completes and before launching `sdd-apply`, inspect `Review Workload Forecast`.

If it says `Chained PRs recommended: Yes`, `400-line budget risk: High`, estimated changed lines exceed 400, or `Decision needed before apply: Yes`, apply cached `delivery_strategy`:

- `ask-on-risk`: stop and ask whether to split or proceed with `size:exception`.
- `auto-chain`: split automatically; ask for `chain_strategy` only if missing.
- `single-pr`: stop and require/record `size:exception` before apply.
- `exception-ok`: continue and tell `sdd-apply` this run uses `size:exception`.

Any other `delivery_strategy` value is invalid. Do NOT pick the nearest branch and do NOT proceed: STOP, report the unrecognised value, and re-collect the delivery strategy before launching `sdd-apply`.

Always pass the resolved `delivery_strategy`, `chain_strategy`, and PR boundary/exception to `sdd-apply`.

When launching `sdd-apply`, always include the resolved `delivery_strategy`, `chain_strategy`, and any chosen PR boundary/exception in the prompt.

<!-- gentle-ai:sdd-model-assignments -->


## SDD Testing Workflow

Testing pipeline for feature validation. Supports browser, backend, API, and mixed testing modes. There is no archive phase in the testing pipeline — testing artifacts live in engram (plus the projected report file); there is nothing to merge or close out the way the development pipeline's `archive` does.

The orchestrator is responsible for surfacing this pipeline the same way it surfaces the SDD development pipeline — it must NOT stay silent and let a testing request fall through to an ad-hoc test run. Route by the intent behind the request, across three tiers. Classify the intent regardless of the language the user writes in, and respond in that same language — the descriptions below are intent categories, not phrases to match literally.

**Default bias: when in doubt, offer.** If you are unsure whether a request is testing intent at all, lean toward offering the pipeline rather than answering ad hoc. A missed offer is the failure mode to avoid — a non-technical user (PM, Design, QA) will not know the pipeline exists, will not type a slash command, and will not phrase things the "right" way. Treat any request that touches "is this working / does this look right / can you check this" as a candidate for the pipeline. The cost of an unwanted offer is one extra line the user ignores; the cost of a missed offer is the whole pipeline going unused.

**Tier 1 — Clear testing intent (do NOT ask WHICH pipeline; DO offer the depth).**
The user names a concrete feature, flow, card, screen, or endpoint to test, validate, or compare against a design. The intent is unambiguous, so do not ask "which pipeline" — it is the testing one. But do NOT silently assume the full ceremony and start acting: on the FIRST testing request of the session, surface the DEPTH choice once — the full SDD testing pipeline (explore → suites review → plan → run → report, persisted and reusable) versus a quick direct validation (a one-off check, no artifacts) — unless the user already named one (e.g. "/sdd-test", "usá el pipeline", or "solo fijate rápido"). Cache the choice for the session. Then proceed on the chosen path.

**Tier 2 — Ambiguous validation intent (default to the quick check).**
The user expresses an intent to validate, check, or QA something, but it is ambiguous whether they want the full pipeline or a quick one-off check (e.g. "does this work?", "make sure the new screen is OK before the demo"). Default to the quick ad-hoc validation and say so in one sentence; casual phrasing is not a request for pipeline artifacts. Offer the full pipeline (explore → plan → run → report, which persists a reusable plan and report) only when the request implies reusable artifacts — a regression suite, a shareable report, repeated future runs — or the user asks for it. If the pipeline is chosen but no concrete target was named, run the guided intake (see `/sdd-test` wizard) to collect what to test before launching `explore-testing`.

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
   - **Sin código (Chrome extension)** (the `chrome-extension` engine / `live (no code)` persona) — Claude drives an open Chrome browser with the user's real session. No scripts are written or committed. Ideal for non-technical users, one-off validation, or flows that require a real logged-in session.
   - **Playwright (código)** (the `playwright` engine / `playwright (code)` persona) — Claude writes and runs Playwright spec files. Cross-browser, reproducible, leaves artifacts in the repo. Requires repo write access and Playwright installed.
   - **Maestro (visual device)** (the `maestro` engine / `maestro (visual device)` persona) — Claude drives Android, iOS, or web/Chromium flows through Maestro MCP or CLI. It is device-first visual E2E, can run against a real device, emulator, simulator, or supported web surface, and only persists `.maestro/**/*.yaml` flows when the user explicitly allows repo writes. App source changes are never required.

   Present all options with a brief description. Do NOT pick one based on what tools are available. Wait for the user's explicit choice before proceeding. The chosen engine/persona is passed to `plan-testing` and `run-testing` and overrides any per-case engine assignment where applicable.

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
| `explore-testing` | Consult engram first (same-project prior testing + cross-project analogous flows) and read the `suites` artifact if present; read codebase, existing Playwright and `.maestro/**/*.yaml` flows, TESTING_CONTEXT.md, Figma frames, ClickUp task — produce testing scope including likely testing modes; for browser/mobile cases, flag engine sensitivity (real-session Chrome dependency → `chrome-extension`; multi-browser or Safari coverage → `playwright`; device-first or native-app validation → `maestro`) |
| **suites gate** (orchestrator, not a sub-agent) | MANDATORY human-in-the-loop checkpoint between explore and plan. Resolve test-case suites per the cached source (generate / conversation / engram), SHOW them to the user, collect priority + edge-case decisions, and persist the APPROVED suites to `testing/{project}/{feature}/suites`. Never auto-skip — automatic mode does not bypass it. See "Test-Case Source → Suites resolution gate". |
| `plan-testing` | DERIVE the executable plan from the `suites` artifact when present (do NOT re-invent cases); otherwise generate from exploration. Structured test cases with IDs, priorities, mode per case, browser targets (browser mode only), engine per case (`playwright` / `chrome-extension` / `maestro` for browser; `maestro` for mobile), visual-diff flags (browser/mobile mode with a design reference only) |
| `run-testing` | Delegated to the sub-agent for every engine. Branch on the session persona engine: `live (no code)` → Chrome extension against the deployed / preview URL; `playwright (code)` → Playwright CLI via Bash + spec files; `maestro (visual device)` → Maestro MCP/CLI for Android / iOS / web with optional `.maestro/**/*.yaml` flows when the persona permits persisted artifacts. Project test runner for backend; HTTP calls for api; mobile mode runs through Maestro — perform visual diff only when mode is browser or mobile and a design reference is available. **Read-only for application code: failures are recorded as findings, never fixed.** |
| `report-testing` | Produce human-readable summary — pass/fail table with Engine column for browser/mobile rows, evidence references (browser/device + screenshot/hierarchy when present), findings grouped by mode when mixed, follow-up items. This is the final phase of the testing pipeline. |

### Engram pre-flight guard (MANDATORY — blocking)

Run this BEFORE anything else in the testing pipeline (before `explore-testing`, before the setup checkpoints below). The testing pipeline is engram-only: every phase reads and writes engram. If engram is not reachable, the run will fail cryptically at the first `mem_save` mid-flow — unacceptable for a non-technical user.

1. Verify engram is reachable with a lightweight call (e.g. `mem_current_project` or a trivial `mem_search`).
2. If it responds → proceed.
3. If it is NOT available → STOP. Do NOT enter the pipeline. Tell the user plainly that engram (the memory the pipeline depends on) is unavailable and instruct them to enable or repair the configured Engram plugin/tool integration. Do not suggest shell commands or standalone MCP registration. Unlike the tool prerequisites below, this is a hard block — engram absence is not "best-effort continue".

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
| `browser` | `chrome-extension` | Chrome extension installed and connected | Check extension status before running | "Chrome extension not detected. Connect it before running, or switch engines if a real Chrome session is not required." |
| `browser` | `chrome-extension` | Chrome browser open | — | "Chrome must be open for the extension to drive it." |
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
- Which execution engine / persona? (`live (no code)` for a real Chrome session, `playwright (code)` for reproducible cross-browser coverage, or `maestro (visual device)` for device-first Android / iOS / web validation)
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

- **`chrome-extension` / `live (no code)` → delegate.** The sub-agent drives the Claude Chrome extension against the deployed / preview URL. This is the real-session web path for non-technical users — it must remain a first-class, delegatable engine.
- **`maestro` / `maestro (visual device)` → delegate.** The sub-agent drives Android, iOS, or web/Chromium flows through Maestro. Prefer Maestro MCP tools (`list_devices`, `inspect_screen`, `take_screenshot`, `run`, `cheat_sheet`, `open_maestro_viewer`) when available; otherwise fall back to Maestro CLI (`maestro test`, `maestro hierarchy`) where possible. Do NOT edit app source. Persist `.maestro/**/*.yaml` only when the persona explicitly allows repo-backed flows; otherwise keep YAML inline / ephemeral.
- **`playwright` / `backend` / `api` → delegate.** Bash-driven (`playwright test`, the project test runner, `curl`) plus engram.
- **`mixed`**: delegated as parallel execution units (see below), one runner per unit, results merged.

There is NO default engine. The engine/persona is a blocking product choice (see Testing Setup Questions). `live (no code)`, `playwright (code)`, and `maestro (visual device)` are peer first-class options; choose the one that fits the target surface and the kind of evidence the user wants.

#### Parallel execution — fan out N runners (read second)

run-testing is NOT a single runner by default. Most test cases are independent (non-blocking), so the orchestrator fans out **N `sdd-run-testing` sub-agents in parallel**, one per execution unit, and merges their results. A single runner is only correct when the plan reduces to one unit.

**Execution units come from the plan.** `plan-testing` partitions the cases into execution units (see its output contract):
- An **independent case** is its own unit — parallelizable with every other independent unit.
- A **dependency chain** (case A writes data that case B reads, e.g. `CAT-05` seeds a fixture for `CAT-06`) is ONE unit that runs its cases sequentially inside a single runner. Never split a chain across runners.

**The orchestrator launches one runner per unit, concurrently**, passing each runner only its unit's cases. Bound the fan-out by:
1. **Data dependencies** — already encapsulated: chains are single units, so ordering is preserved within a runner.
2. **Shared mutable state** — two units that write the SAME data (same record, same user's state) would collide if concurrent. `plan-testing` flags these as conflicting; the orchestrator serializes conflicting units (or relies on isolated per-unit test data when the plan says it is available). Read-only cases never conflict.
3. **Engine concurrency** — `playwright` / `backend` / `api` units parallelize freely (isolated processes / browser contexts). `chrome-extension` / `live` units are bounded by how many real browser sessions are available and by the user's wish to observe the run. `maestro` units are bounded by how many devices, emulators, simulators, or web targets are actually available and by whether the user wants to watch the run. Do not auto-create or auto-provision extra targets without asking first.
4. **A sane concurrency cap** — do not launch dozens at once; batch to a reasonable number of concurrent runners.

**Per-unit model.** Apply the conditional model per runner: a unit whose cases include `visual diff: yes` launches with `opus`; purely mechanical units launch with `sonnet`. So visual units get the strong vision model without paying for it on the rest.

**Result merge (orchestrator-owned).** Each runner writes its own shard observation under `testing/{project}/{feature}/run/{session-id}/{unit-id}` (a sole runner writes the consolidated `testing/{project}/{feature}/run/{session-id}` directly) and returns its `run_digest`. The orchestrator MERGES all shards into the consolidated `testing/{project}/{feature}/run/{session-id}` and ALWAYS writes `testing/{project}/{feature}/run/latest` itself — even for a single runner; runners never write `run/latest`. The `run/latest` content MUST include the top-level fields `session_id: "{session-id}"` and `session_topic_key: "testing/{project}/{feature}/run/{session-id}"`, so `report-testing` can read the `session_id` and resolve one latest run. Surface a combined run digest to the user.

The session **persona engine** (chosen in Testing Setup Questions) takes precedence for browser/mobile cases: `live (no code)` forces `chrome-extension` for browser cases (run against the deployed / preview URL, no spec files written); `playwright (code)` forces `playwright` for browser cases; `maestro (visual device)` forces `maestro` for browser cases the user chose to validate through Chromium/web and for ALL `mobile` cases. Only when no persona was set does the per-case `engine` determined during `plan-testing` apply. With that precedence in mind, automated test runs dispatch based on the `mode` and, for UI cases, the resolved `engine`:

- **`browser`**: Three engines are available. The plan assigns one per test case.

  - **`engine: playwright`**: Run via Playwright CLI via Bash, headless or headed. Cross-browser across Chromium / Firefox / WebKit as specified in the test plan. Use for: multiple browsers required, regression suites, repeatable runs, anything needing visual diff across browsers.

  - **`engine: chrome-extension`**: Drive a real Chrome session via the Claude Chrome extension. Single browser only (Chrome). Use for: flows that depend on a real authenticated session, one-shot exploratory validation, or when the user wants to observe the run live in their own Chrome window. Visual diff still works when a design reference is present, but coverage is Chrome-only.

  - **`engine: maestro`**: Run web/Chromium or device-proxy flows through Maestro MCP or CLI. Use for: device-first visual E2E, the same flow needing to span mobile + web, or a no-code browser run where Chromium coverage is sufficient. Evidence comes from Maestro screenshots / hierarchy, not Playwright spec files.

  Browser inspection helpers (Chrome DevTools MCP, Playwright MCP, Maestro helpers) may be used for DOM or screen inspection, but they do not replace the chosen execution engine.

- **`mobile`**: `engine: maestro` only. Drive Android / iOS flows through Maestro MCP or CLI. Requires a reachable device/emulator/simulator (or approved cloud target) plus a known `appId`, bundle ID, app path, or launch target. Prefer inline YAML while refining a run; only write `.maestro/**/*.yaml` when the persona explicitly allows persisted flows.

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

The checklist extracts typography, color, spacing, and layout specs from the design reference and verifies them against computed DOM styles or device-observed UI properties. Pixel diff screenshots are informative artifacts for human review, NOT a pass/fail criterion. Screenshot persistence is persona-aware: `playwright (code)` saves them under a temporary directory outside the repository tree (e.g. `/tmp/sdd-testing/{feature}/screenshots/`); `live (no code)` does NOT write to the repo — the screenshot is described in the run artifact only; `maestro (visual device)` prefers Maestro screenshots and hierarchy captures attached to the run artifact or saved to a temporary directory outside the repository tree. `.maestro/**/*.yaml` is the only repo-backed Maestro artifact, and only when the persona explicitly permits persisted flows. Screenshots are never written into the repository tree.

See the `visual-diff` skill for the full methodology.

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

## Agens choice transport

Use one grouped blocking choice prompt when the Agens runtime exposes a choice
mechanism that can represent every option. Otherwise present the complete
question, options, default, consequence, and answer syntax in chat, block for
the reply, and validate it before continuing. Never infer a missing choice.
