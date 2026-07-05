---
description: Fast-forward all SDD planning phases -- proposal through tasks
---

If the native `sdd-orchestrator` agent is available, delegate this command to it.
Otherwise, read `~/.claude/skills/_shared/sdd-orchestrator-workflow.md` first, then follow that workflow inline.

WORKFLOW:
Run these sub-agents in sequence:
1. `sdd-propose` -- create the proposal
2. `sdd-spec` -- write specifications
3. `sdd-design` -- create technical design
4. `sdd-tasks` -- break down into implementation tasks

Present a combined summary after ALL phases complete (not between each one).

CONTEXT:
- Working directory: Detect agent-side before proceeding by running `git rev-parse --show-toplevel` with the Bash tool; if that fails, run `pwd` with the Bash tool.
- Current project: Derive agent-side from the detected working directory basename. Do not use slash-command shell interpolation for this value.
- Change name: $ARGUMENTS
- Execution mode: ask/cache per orchestrator
- Artifact store mode: ask/cache per orchestrator
- Delivery strategy: ask/cache per orchestrator

ENGRAM NOTE:
Sub-agents handle persistence automatically. Each phase saves its artifact to engram with topic_key "sdd/$ARGUMENTS/{type}" where type is: proposal, spec, design, tasks.

Read `~/.claude/skills/_shared/sdd-orchestrator-workflow.md` to coordinate this workflow. Do NOT execute phase work inline when a native sub-agent is available.
