---
description: Run the full testing pipeline — explore, plan, run, report for a feature or flow
---

This is a meta-command handled by the orchestrator. Do NOT invoke it as a skill.

Before running this workflow inline, read `~/.claude/skills/_shared/sdd-orchestrator-workflow.md`; it contains the lazy-loaded testing pipeline, prerequisites, suites gate, and routing rules.

CONTEXT:
- Working directory: !`pwd`
- Current project: (last path component of the working directory above — no shell command needed, derive it from the path)
- Feature, flow, or ClickUp task reference: $ARGUMENTS

TASK:
Run the full SDD testing pipeline for "$ARGUMENTS":

  explore-testing → [resolve test-case suites + human review] → plan-testing → run-testing → report-testing

The orchestrator must:

0. GUIDED INTAKE — if $ARGUMENTS is empty, vague, or does not name a concrete feature/flow/screen/endpoint:
   Do NOT guess and do NOT abort. Run a plain-language wizard, asking ONE question at a time and waiting
   for each answer before the next. Use everyday wording — assume the user is non-technical (PM, Design,
   QA) and may not know terms like "endpoint", "engine", or "environment". Collect, in this order:

   1. **What do you want to check?** — "¿Qué parte de la app querés revisar? Por ejemplo: 'el login',
      'la pantalla de checkout', 'el formulario de alta'." Accept a plain description; this becomes the feature.
   2. **Where is it?** — "¿Dónde lo vemos? Pegá el link donde está corriendo (local, staging, o preview),
      o decime cómo se abre." This resolves the target environment and base URL.
   3. **Is there a design to compare against?** — "¿Tenés un diseño de referencia (Figma, Zeplin, una captura)?
      Si no, no pasa nada — lo salteamos." Optional; drives visual diff.
   4. **How should I drive it?** — present the three personas in plain language, NOT jargon:
      - "Reviso en vivo, abriendo Chrome con tu sesión real (no escribo código, no toco el repo)." → `live (no code)` / `chrome-extension`
      - "Dejo tests automáticos guardados en el código para repetir después." → `playwright (code)`
      - "Reviso desde un dispositivo, emulador, simulador, o web/Chromium con Maestro (visual, no-code salvo que autorices guardar flujos)." → `maestro (visual device)`
      Recommend the first option for real-session web validation and the third for mobile/device-first validation. This is the persona engine — it is BLOCKING per the Testing Setup Questions; do not assume it.

   If a ClickUp/Jira/Linear task ID or URL was given instead, resolve it first (step 1 below) and only ask
   the wizard questions that the task did not already answer. Once the wizard has the feature, environment,
   optional design reference, and persona, proceed to step 1 as if those had been provided as arguments.

   The wizard answers SATISFY the corresponding Testing Setup Questions — do NOT re-ask persona engine,
   target environment, or design reference afterward. Still resolve the remaining setup questions the wizard
   did not cover (test-case source and execution mode, step 3 below), in the same plain language, only if
   not already clear from context.

1. Detect intent: if $ARGUMENTS is a ClickUp task ID or URL, resolve it first via ClickUp MCP
   (if available) to extract the feature name and acceptance criteria. Otherwise treat $ARGUMENTS
   as the feature name directly.

2. Run the two prerequisites checkpoints defined in the orchestrator Testing Workflow → `### Prerequisites Check` section. Checkpoint 1 runs before explore-testing; Checkpoint 2 runs after plan-testing returns (once modes and engines are known), before run-testing.

3. Ask for execution mode on first run in a session (interactive / automatic).

4. After explore-testing returns and BEFORE launching plan-testing: resolve the test-case suites and
   get the user's sign-off per the orchestrator Testing Workflow → `### Test-Case Source & the test-suite-generator bridge` BEFORE launching
   plan-testing. This is MANDATORY and is NOT skipped in automatic mode.

5. Run each phase as a sub-agent in sequence, pausing between phases in interactive mode. `run-testing` is
   delegated for every engine, including `chrome-extension` / `live (no code)` and `maestro` / `maestro (visual device)` — the sub-agent drives the selected surface directly. It is fanned out into N parallel runners, one per execution unit from the plan (independent cases run concurrently; dependency chains stay ordered in one runner); the orchestrator merges the shards.

6. report-testing is the final phase — surface the report to the user. There is no archive step in the testing pipeline.

ENGRAM PERSISTENCE:
Before starting, search for prior testing work on this feature:
  mcp__plugin_engram_engram__mem_search(query: "testing/{project_slug}/{feature_slug}", project: "{project}")
If a prior plan exists and the user's request is a re-run (not a re-plan), skip explore-testing and
plan-testing: reuse the existing plan, generate a new session ID, and run from run-testing onward.
If the user asks to re-plan or scope has changed, start from explore-testing.

Return a structured result with: status, executive_summary, artifacts, next_recommended, risks.
