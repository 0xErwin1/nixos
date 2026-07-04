---
description: Execute the test plan -- drives the chosen engine (Playwright or Maestro), backend runner, or API calls per the plan.
agent: sdd-orchestrator
subtask: true
---

If the native `sdd-run-testing` sub-agent is available, delegate this command to it.
Otherwise, read the agent file at `~/.config/opencode/agent/sdd-run-testing.md` FIRST, then follow its instructions exactly inline.

CONTEXT:
- Working directory: !`pwd`
- Current project: (last path component of the working directory above — no shell command needed, derive it from the path)
- Feature to run tests for: $ARGUMENTS
- Artifact store mode: engram

TASK:
Execute the test plan for "$ARGUMENTS". Read the plan artifact from engram
(topic_key: "testing/{project_slug}/$ARGUMENTS/plan"), execute the plan's cases via the engine the
plan/persona specifies (`playwright` / `maestro` / `backend` / `api`, with `mobile`
mode running through Maestro), perform visual diff checks where a design reference is available, and
persist raw results to engram.

ENGRAM PERSISTENCE:
Read plan (required):
  mem_search(query: "testing/{project_slug}/$ARGUMENTS/plan", project: "{project}") → mem_get_observation(id)
Save run results: persist per the agent's own Engram Save section (it specifies the correct topic key and observation type) — do not override the type here. The orchestrator owns the session-id, the parallel fan-out across execution units, the shard merge, and `run/latest`. This runner writes only its shard `testing/{project_slug}/$ARGUMENTS/run/{session-id}/{unit-id}` (or the consolidated `run/{session-id}` if it is the sole runner) per the agent's Engram Save section; it does NOT write `run/latest`.

Return a structured result with: status, executive_summary, artifacts, next_recommended, risks.
