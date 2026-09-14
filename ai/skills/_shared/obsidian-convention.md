# Obsidian Storage Convention (SDD artifacts)

## Directory Structure

**ALWAYS** save SDD artifacts to Obsidian using MCP under:

```
projects/{project-name}/spec/{artifact-name}
```

### Path Naming Rules

```
projects/
└── {project-name}/              ← Project name (detected or passed)
    └── spec/
        └── {change-name}--{artifact-type}.md
            ├── {change-name}--proposal.md
            ├── {change-name}--spec.md
            ├── {change-name}--design.md
            └── {change-name}--tasks.md
```

### Artifact Types (in filename)

| Type | Produced By | Example |
|------|-------------|---------|
| `proposal` | sdd-propose | `my-feature--proposal.md` |
| `spec` | sdd-spec | `my-feature--spec.md` |
| `design` | sdd-design | `my-feature--design.md` |
| `tasks` | sdd-tasks | `my-feature--tasks.md` |
| `apply` | sdd-apply | `my-feature--apply-progress.md` |
| `verify` | sdd-verify | `my-feature--verify-report.md` |

## What Gets Saved

### To Obsidian (ALWAYS)
- **Full, complete artifact** with all details
- Markdown format with YAML frontmatter
- Ready for human review and annotation in Obsidian vault

### To Engram (ALWAYS)
- **Brief summary** (1-2 paragraphs)
- Observation ID for recovery after context compaction
- Path to the Obsidian note (for quick navigation)
- Metadata for orchestrator state recovery
- Topic key for upsert capability

## Frontmatter Format

Every artifact saved to Obsidian MUST include:

```yaml
---
type: sdd-{artifact-type}       # sdd-proposal, sdd-spec, sdd-design, etc
change: {change-name}
project: {project-name}
created: {ISO 8601 timestamp}
updated: {ISO 8601 timestamp}
status: draft | in-progress | complete
---
```

## Write Protocol (ALWAYS)

1. Format artifact as Markdown with YAML frontmatter (see Frontmatter Format below)
2. Call Obsidian MCP to write to: `projects/{project-name}/spec/{change-name}--{type}.md`
3. Call Engram `mem_save()` with summary + link back to Obsidian file
4. If mode is `openspec`: also write to `openspec/changes/{change-name}/`
5. Return summary with paths (Obsidian + Engram observation ID) to orchestrator

## Read Protocol

1. When a skill needs a previous artifact, check Obsidian first (full content)
2. If not found, fallback to Engram (quick retrieval)
3. Always use the observation ID from Engram to get latest version if updated

## Example

**Obsidian file path:**
```
projects/my-app/spec/add-dark-mode--spec.md
```

**Engram summary:**
```
title: sdd/add-dark-mode/spec
topic_key: sdd/add-dark-mode/spec
project: my-app
content: |
  Spec saved to Obsidian: projects/my-app/spec/add-dark-mode--spec.md

  Summary: Added dark mode toggle in settings, with localStorage persistence and three color schemes (light, dark, auto).

  Requirements: 5 (all added)
  Scenarios: 8 total (6 happy path, 2 edge cases)
```

## Recovery After Compaction

The orchestrator saves state to Engram with Obsidian paths:

```yaml
artifacts:
  proposal: projects/my-app/spec/add-dark-mode--proposal.md
  spec: projects/my-app/spec/add-dark-mode--spec.md
  design: projects/my-app/spec/add-dark-mode--design.md
```

Skills can then read directly from Obsidian using the stored paths.
