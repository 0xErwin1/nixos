---
description: Generate a human-readable test report from run results
agent: sdd-orchestrator
subtask: true
---

If the native `sdd-report-testing` sub-agent is available, delegate this command to it.
Otherwise, read the agent file at `~/.config/opencode/agent/sdd-report-testing.md` FIRST, then follow its instructions exactly inline.

CONTEXT:
- Working directory: !`pwd`
- Current project: (last path component of the working directory above — no shell command needed, derive it from the path)
- Feature to report on: $ARGUMENTS
- Artifact store mode: engram

TASK:
Produce a human-readable test report for "$ARGUMENTS". Read the latest run artifact
(topic_key: "testing/{project_slug}/$ARGUMENTS/run/latest") — reuse the `session_id` it carries — and
the test plan (topic_key: "testing/{project_slug}/$ARGUMENTS/plan") from engram, then generate a summary
table, visual-diff findings, and plain-language follow-up items.
Do NOT write report files into the repository tree — persist the report in engram and return it in full so it can be surfaced (and optionally stored in Obsidian).

ENGRAM PERSISTENCE:
Read run results (required):
  mem_search(query: "testing/{project_slug}/$ARGUMENTS/run/latest", project: "{project}") → mem_get_observation(id)
Read plan (required):
  mem_search(query: "testing/{project_slug}/$ARGUMENTS/plan", project: "{project}") → mem_get_observation(id)
Save report: persist per the agent's own Engram Save section (it specifies the correct topic key and observation type) — do not override the type here.

Return a structured result with: status, executive_summary, artifacts, next_recommended, risks.
