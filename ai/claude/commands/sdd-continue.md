---
description: Continue the next SDD phase in the dependency chain
---

If the native `sdd-orchestrator` agent is available, delegate this command to it.
Otherwise, read `~/.claude/skills/_shared/sdd-orchestrator-workflow.md` first, then follow that workflow inline.

WORKFLOW:
1. Read `~/.claude/skills/_shared/sdd-status-contract.md` and produce structured status before acting. A native status dispatcher is authoritative only when the session artifact store is `openspec` or `hybrid`; it reads only `openspec/changes/` and cannot see Engram-backed changes. When the session artifact store is `engram`, do NOT rely on any native dispatcher output (`blocked`, `Active OpenSpec change not found`, `nextRecommended: sdd-new`) for a change that exists -- resolve status entirely from Engram (`mem_search` + `mem_get_observation` on the change's topic keys) using the manual status schema. If the change is missing and more than one active change exists, ask the user to choose and STOP. Do not guess.
2. Check which artifacts already exist for the active change (proposal, specs, design, tasks)
3. Determine the next phase needed based on the dependency graph:
   proposal -> [specs ∥ design] -> tasks -> apply -> verify -> archive
4. Launch the appropriate sub-agent(s) for the next phase only when structured status says the dependency is `ready`. Carry `actionContext` and allowed edit roots into any sub-agent launch.
5. Present the result and ask the user to proceed

CONTEXT:
- Working directory: Detect agent-side before proceeding by running `git rev-parse --show-toplevel` with the Bash tool; if that fails, run `pwd` with the Bash tool.
- Current project: Derive agent-side from the detected working directory basename. Do not use slash-command shell interpolation for this value.
- Change name: $ARGUMENTS
- Execution mode: ask/cache per orchestrator
- Artifact store mode: ask/cache per orchestrator
- Delivery strategy: ask/cache per orchestrator

ENGRAM NOTE:
To check which artifacts exist, search: mem_search(query: "sdd/$ARGUMENTS/", project: "{project}") to list all artifacts for this change.
Sub-agents handle persistence automatically with topic_key "sdd/$ARGUMENTS/{type}".

Read `~/.claude/skills/_shared/sdd-orchestrator-workflow.md` to coordinate this workflow. Do NOT execute phase work inline when a native sub-agent is available.
