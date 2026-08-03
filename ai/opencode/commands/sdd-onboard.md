---
description: Guided SDD walkthrough -- onboard a user through the full SDD cycle using their real codebase
agent: sdd-orchestrator
subtask: true
---

CONTEXT:
- Working directory: !`echo -n "$(pwd)"`
- Current project: !`echo -n "$(basename $(pwd))"`

PREFLIGHT:
Use the existing SDD preflight decision block. It must supply the pace, artifact-store mode, and review-budget choices. If it is absent or incomplete, return a blocking envelope containing every question, option, default, consequence, and answer syntax; do not choose or omit a value.

TASK:
Launch the configured hidden `sdd-onboard` agent with the working directory, project, artifact-store mode, and complete preflight decision block. Tell it to read `~/.config/opencode/skills/sdd-onboard/SKILL.md` and `~/.config/opencode/skills/_shared/sdd-phase-common.md` before acting.

Relay a blocked-choice envelope losslessly. Otherwise relay the agent's structured `status`, `executive_summary`, `artifacts`, and `next_recommended` result without claiming work or persistence that did not occur.
