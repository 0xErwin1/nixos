---
description: Commit Message is a tool designed to generate a Git commit title and description following the Conventional Commits format.
agent: plan
---

Generate a Git commit title and description following the Conventional Commits format.

Allowed commit types:
feat, fix, refactor, perf, docs, style, chore

Rules:
- Do NOT create a commit
- Do NOT push, amend, rebase, or modify the repository
- Only display the proposed commit message
- Do NOT include test-related changes

Context gathering:
- You MAY use the Git MCP to read repository state (diff, status, log)
- If executing any git command is required, ASK for explicit permission first
- Read-only operations only unless permission is granted

Title:
- Format: <type>(optional scope): short summary
- Max 72 characters
- Clear, simple language, no buzzwords

Description:
- One short paragraph (use more only if strictly necessary)
- Explain what changed and why, not how
- Simple, direct wording
- No code blocks

Write like a principal software engineer who values simplicity over complexity.
