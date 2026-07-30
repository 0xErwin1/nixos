# Obsidian Storage Convention (SDD artifacts)

This is the convention for the `obsidian` artifact-store mode. It applies when
the orchestrator passes `artifact_store.mode: obsidian`.

## How the mode works

In `obsidian` mode, SDD artifacts are persisted to two places:

- **The Obsidian vault** — the full, human-readable artifact, written via the
  Obsidian MCP tools (`mcp__obsidian__*`). This is the copy a person reads and
  annotates.
- **Engram** — a brief summary plus a pointer back to the vault note, for
  cross-session recovery and compaction survival.

The vault is governed by its own `AGENTS.md`. Read that file and respect the
vault's general conventions (frontmatter style, links, quality rules). SDD
artifacts live in a dedicated `sdd/` area that is separate from the vault's
knowledge-wiki content — do not file them as wiki pages.

Never write artifacts into the project repository tree in this mode.

## Directory structure

SDD artifacts go under `sdd/` in the vault, one folder per project:

```
sdd/
└── {project}/
    └── {change}-{artifact}-{date}.md
```

- `{project}` — the project name (detected or passed by the orchestrator).
- `{change}` — the change slug.
- `{artifact}` — the artifact type (see table below).
- `{date}` — the date the artifact was produced, `YYYY-MM-DD`.

The `sdd-init` artifact has no change slug; name it `init-{date}.md`.

### Artifact types

| Type | Produced by | Example filename |
|------|-------------|------------------|
| `init` | sdd-init | `init-2026-05-09.md` |
| `exploration` | sdd-explore | `oauth-login-exploration-2026-05-09.md` |
| `proposal` | sdd-propose | `oauth-login-proposal-2026-05-09.md` |
| `spec` | sdd-spec | `oauth-login-spec-2026-05-09.md` |
| `design` | sdd-design | `oauth-login-design-2026-05-09.md` |
| `tasks` | sdd-tasks | `oauth-login-tasks-2026-05-09.md` |
| `delivery-strategy` | sdd-tasks | `oauth-login-delivery-strategy-2026-05-09.md` |
| `apply-progress` | sdd-apply | `oauth-login-apply-progress-2026-05-09.md` |
| `verify-report` | sdd-verify | `oauth-login-verify-report-2026-05-09.md` |
| `archive-report` | sdd-archive | `oauth-login-archive-report-2026-05-09.md` |

## What gets saved

### To the Obsidian vault

- The full, complete artifact in Markdown, ready for human review.
- A light YAML frontmatter block:

```yaml
---
type: sdd-{artifact}        # sdd-proposal, sdd-spec, sdd-design, ...
change: {change}
project: {project}
created: {YYYY-MM-DD}
updated: {YYYY-MM-DD}
status: draft | in-progress | complete
---
```

### To Engram

- A brief summary (1-2 paragraphs).
- The vault path of the note, for navigation.
- A `topic_key` for upsert and orchestrator state recovery.

## Write protocol

1. Format the artifact as Markdown with the frontmatter above.
2. Use the Obsidian MCP to write it to `sdd/{project}/{change}-{artifact}-{date}.md`.
3. Call Engram `mem_save()` with the summary and the vault path.
4. Return the vault path and the Engram observation ID to the orchestrator.

## Read protocol

1. When a skill needs a previous artifact, read it from the vault via the
   Obsidian MCP (full content).
2. If it is not found there, fall back to Engram for a quick summary.

## Recovery after compaction

The orchestrator persists state to Engram with the vault paths:

```yaml
artifacts:
  proposal: sdd/oauth-login/oauth-login-proposal-2026-05-09.md
  spec: sdd/oauth-login/oauth-login-spec-2026-05-09.md
  design: sdd/oauth-login/oauth-login-design-2026-05-09.md
```

Skills can then read directly from the vault using the stored paths.

## Example

Vault note path:

```
sdd/oauth-login/oauth-login-spec-2026-05-09.md
```

Engram summary:

```
title: sdd/oauth-login/spec
topic_key: sdd/oauth-login/spec
project: oauth-login
content: |
  Spec saved to Obsidian: sdd/oauth-login/oauth-login-spec-2026-05-09.md

  Summary: GitHub OAuth login flow with token refresh and session binding.

  Requirements: 5 (all added)
  Scenarios: 8 total (6 happy path, 2 edge cases)
```
