If the native `sdd-plan-testing` sub-agent is available, delegate this command to it.
Otherwise, read the agent file at `~/.codex/agents/sdd-plan-testing.md` FIRST, then follow its instructions exactly inline.

CONTEXT:
- Working directory: !`pwd`
- Current project: (last path component of the working directory above — no shell command needed, derive it from the path)
- Feature to plan tests for: $ARGUMENTS
- Artifact store mode: engram

TASK:
Produce a structured test plan for "$ARGUMENTS". Derive the test plan from the approved suites when
present (the suites gate runs before this phase), otherwise from the explore artifact; include
execution units for parallelization per the agent. Do NOT write Playwright code.

ENGRAM PERSISTENCE:
Read exploration (required):
  mem_search(query: "testing/{project_slug}/$ARGUMENTS/explore", project: "{project}") → mem_get_observation(id)
Save plan: persist per the agent's own Engram Save section (it specifies the correct topic key and observation type) — do not override the type here.

Return a structured result with: status, executive_summary, artifacts, next_recommended, risks.
