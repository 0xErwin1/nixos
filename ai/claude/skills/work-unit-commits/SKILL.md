---
name: work-unit-commits
description: "Plan commits as reviewable work units. Trigger: implementation, commit splitting, splitting work across PRs, or keeping tests and docs with code."
license: Apache-2.0
metadata:
  author: iperez
  version: "1.0"
---

## When to Use

Load this skill when deciding what belongs in each commit or PR.

Use it for:

- Splitting a feature into reviewable work.
- Preparing commits before opening a PR.
- Splitting a large change across separate PRs.
- Keeping reviewer cognitive load healthy.

## Critical Rules

| Rule | Requirement |
|------|-------------|
| Commit by work unit | A commit represents a deliverable behavior, fix, migration, or docs unit. |
| Do not commit by file type | Avoid `models`, then `services`, then `tests` if none works alone. |
| Keep tests with code | Tests belong in the same commit as the behavior they verify. |
| Keep docs with the user-visible change | Docs belong with the feature or workflow they explain. |
| Tell a story | A reviewer should understand why each commit exists from its diff and message. |
| Future PR-ready | Each commit should stand on its own if the change later needs splitting across PRs. |

## Work Unit Checklist

Before committing, confirm:

- [ ] The commit has one clear purpose.
- [ ] The repo still makes sense after applying only this commit.
- [ ] Tests or docs for this unit are included when relevant.
- [ ] Rollback is reasonable without reverting unrelated work.
- [ ] Focused test command and exact result are recorded.
- [ ] Runtime harness command/scenario and exact result are recorded, or explicit `N/A` explains why no runtime boundary exists.
- [ ] Rollback boundary names the exact files/behavior removable without unrelated work.
- [ ] The commit message explains the outcome, not the file list.

## Split Examples

| Weak split | Better work-unit split |
|------------|------------------------|
| `add models` | `feat(auth): add token validation domain model and tests` |
| `add services` | `feat(auth): wire token validation into login flow` |
| `add tests` | Tests included with each behavior commit |
| `update docs` | Docs included with the user-facing change they explain |

## PR Relationship

Use work-unit commits as the foundation for whatever PR shape the change ends up needing:

1. Build the smallest independent work unit.
2. Include verification for that unit.
3. Commit it with a Conventional Commit message.
4. If the change grows past a comfortable review size, split it across separate PRs along existing commit boundaries — well-shaped commits make that a regrouping, not a rewrite.

## SDD Relationship

When `sdd-tasks` produces a Review Workload Forecast, treat it as advice about review cost, not as an instruction:

- Low risk: keep work-unit commits inside one PR.
- Medium risk: commit by work unit and watch changed lines before PR creation.
- High risk: suggest landing the work as separate PRs. The user decides; a high forecast never blocks implementation and never shrinks the work.
- Count authored additions plus deletions for the size estimate. Exclude generated goldens from that authored count, but include every generated file in complete snapshot identity.

Each SDD work unit should map cleanly to a commit or PR with:

- clear start state,
- clear finished state,
- verification in the same unit,
- rollback that does not remove unrelated work.

Its implementation evidence MUST include:

- Focused test command and exact result.
- Runtime harness command/scenario and exact result, or explicit `N/A` with reason.
- Rollback boundary stated independently of commit creation; uncommitted work units still require it.

## Commands

```bash
# Review the story before committing
git diff --stat
git diff --cached --stat

# Check recent commit style
git log --oneline -5
```
