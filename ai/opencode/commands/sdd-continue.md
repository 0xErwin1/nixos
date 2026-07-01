---
description: Continue the next SDD phase in the dependency chain
agent: sdd-orchestrator
---

Follow the SDD orchestrator workflow to continue the active change.

WORKFLOW:
1. Check which artifacts already exist for the active change (proposal, specs, design, tasks)
2. Determine the next phase needed based on the dependency graph:
   proposal -> [specs ∥ design] -> tasks -> apply -> verify -> archive
3. Launch the appropriate sub-agent(s) for the next phase only if authoritative status says the dependency is ready. A native status dispatcher is authoritative only when the session artifact store is `openspec` or `hybrid`; it reads only `openspec/changes/` and cannot see Engram-backed changes. When the session artifact store is `engram`, do NOT rely on any native dispatcher output (blocked, Active OpenSpec change not found, next_recommended -> sdd-new) for a change that exists -> resolve status entirely from Engram (mem_search + mem_get_observation on the change topic keys) using the manual status schema. Route only by `next_recommended` and dependency states; never infer from free text. If blocking reasons are non-empty, do not proceed to apply, archive, or terminal work. If `next_recommended` is `verify`, verification/remediation may run only to refresh evidence; if it is `resolve-blockers`, report the blocking reasons and stop; if it is a planning token (`propose`, `spec`, `design`, or `tasks`), launch the corresponding planning phase.
4. Present the result and ask the user to proceed

CONTEXT:
- Working directory: !`echo -n "$(pwd)"`
- Current project: !`echo -n "$(basename $(pwd))"`
- Change name: $ARGUMENTS
- Execution mode: ask/cache per orchestrator
- Artifact store mode: ask/cache per orchestrator
- Delivery strategy: ask/cache per orchestrator

ENGRAM NOTE:
To check which artifacts exist in engram/hybrid, search: mem_search(query: "sdd/$ARGUMENTS/", project: "{project}") to list all artifacts for this change.
Sub-agents handle persistence automatically using the selected artifact store.

Read the orchestrator instructions to coordinate this workflow. Do NOT execute phase work inline -- delegate to sub-agents.
