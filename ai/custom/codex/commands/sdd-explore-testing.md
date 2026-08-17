If the native `sdd-explore-testing` sub-agent is available, delegate this command to it.
Otherwise, read the agent file at `~/.codex/agents/sdd-explore-testing.md` FIRST, then follow its instructions exactly inline.

CONTEXT:
- Working directory: !`pwd`
- Current project: (last path component of the working directory above — no shell command needed, derive it from the path)
- Feature or flow to investigate: $ARGUMENTS
- Artifact store mode: engram

TASK:
Investigate the feature or flow "$ARGUMENTS" from a testing perspective. Read codebase files,
check for TESTING_CONTEXT.md, TESTING_SETUP.md, ARCHITECTURE.md, GLOSSARY.md at repo root, identify auth
requirements, test data needs, and design references (Figma, Zeplin, screenshot, or other) and task
references (ClickUp, Jira, or other). Do NOT write tests.

ENGRAM PERSISTENCE:
Read project context (optional):
  mem_search(query: "sdd-init/{project}", project: "{project}") → if found, mem_get_observation(id)
Save exploration: persist per the agent's own Engram Save section (it specifies the correct topic key and observation type) — do not override the type here.

This is an exploration only — do NOT create any files or modify code.

Return a structured result with: status, executive_summary, artifacts, next_recommended, risks.
