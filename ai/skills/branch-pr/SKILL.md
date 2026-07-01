---
name: branch-pr
description: "Create pull requests that follow the repo's own conventions. Trigger: creating, opening, or preparing PRs for review."
license: Apache-2.0
metadata:
  author: iperez
  version: "3.0"
---

## When to Use

Use this skill when:
- Creating a pull request for any change
- Preparing a branch for submission
- Helping a contributor open a PR

---

## Core Principle

**Follow the repository's own conventions.** Do not impose a fixed checklist. Before opening a PR, read what the repo actually requires and match it. Issue linkage, labels, and specific body sections are required only when the repo asks for them.

---

## Workflow

```
1. Detect the repo's contribution conventions (see below)
2. Create a branch (see Branch Naming)
3. Implement changes with conventional commits
4. Run whatever checks the repo defines (lint, tests, shellcheck, etc.)
5. Open the PR following the repo's template and norms
6. Apply labels / link issues only if the repo requires them
7. Wait for the repo's automated checks to pass
```

---

## Detecting Repo Conventions

Before writing the PR, inspect the repo and adopt what you find:

| Source | What it tells you |
|--------|-------------------|
| `.github/PULL_REQUEST_TEMPLATE.md` | Required PR body sections; fill them as written |
| `CONTRIBUTING.md` / `CONTRIBUTING/` | Branch, commit, issue, and review rules |
| `.github/workflows/*` | Automated checks that gate merge (issue linkage, labels, lint, tests) |
| Existing labels (`gh label list`) | Whether a label taxonomy exists and which to apply |
| Recent merged PRs (`gh pr list --state merged`) | De-facto norms for titles, linkage, and body shape |
| `.github/ISSUE_TEMPLATE/` | Whether the project is issue-first |

If the repo enforces issue linkage or a label taxonomy via CI or CONTRIBUTING, comply with it. If it does not, do **not** invent one — keep the PR clean and minimal.

When conventions are absent or unclear, fall back to the sensible defaults below and state what you assumed.

---

## Branch Naming (default)

Unless the repo defines its own scheme, use `type/description` — lowercase, no spaces, only `a-z0-9._-` in the description:

```
^(feat|fix|chore|docs|style|refactor|perf|test|build|ci|revert)\/[a-z0-9._-]+$
```

| Type | Example |
|------|---------|
| Feature | `feat/user-login` |
| Bug fix | `fix/zsh-glob-error` |
| Chore | `chore/update-ci-actions` |
| Docs | `docs/installation-guide` |
| Refactor | `refactor/extract-shared-logic` |
| Performance | `perf/reduce-startup-time` |
| Test | `test/add-setup-coverage` |
| Build | `build/update-shellcheck` |
| CI | `ci/add-branch-validation` |
| Revert | `revert/broken-setup-change` |

If the repo's existing branches follow a different pattern, match theirs instead.

---

## PR Body (default)

If the repo has a `PULL_REQUEST_TEMPLATE.md`, use it verbatim. Otherwise, a good default body contains:

1. **Summary** — 1-3 bullets of what the PR does and why.
2. **Changes** — a short table of files and what changed.
3. **Test plan** — what you ran or verified (the repo's lint/test commands).

Add these only when the repo calls for them:

- **Linked issue** (`Closes #N`, `Fixes #N`, `Resolves #N`) — when the project is issue-first or CI checks for it.
- **PR type / labels** — when the repo maintains a label taxonomy.

Every PR must explain **what changed and why**. No description, no merge.

---

## Conventional Commits (default)

Unless the repo specifies otherwise, commit messages follow:

```
^(build|chore|ci|docs|feat|fix|perf|refactor|revert|style|test)(\([a-z0-9\._-]+\))?!?: .+
```

**Format:** `type(scope): description` or `type: description`

- `type` — one of: `build`, `chore`, `ci`, `docs`, `feat`, `fix`, `perf`, `refactor`, `revert`, `style`, `test`
- `(scope)` — optional, lowercase with `a-z0-9._-`
- `!` — optional, indicates a breaking change
- `description` — required, starts after `: `

Examples:
```
feat(scripts): add Codex support to setup.sh
fix(skills): correct topic key format in sdd-apply
docs(readme): update multi-model configuration guide
refactor(skills): extract shared persistence logic
feat!: redesign skill loading system
```

If the repo maps commit types to PR labels (check CONTRIBUTING or existing PRs), apply that mapping.

---

## Commands

```bash
# Inspect conventions first
gh repo view
cat .github/PULL_REQUEST_TEMPLATE.md 2>/dev/null
gh label list 2>/dev/null
gh pr list --state merged --limit 5

# Create branch (default scheme)
git checkout -b feat/my-feature main

# Run the repo's own checks before pushing (example)
shellcheck scripts/*.sh

# Push and create PR
git push -u origin feat/my-feature
gh pr create --title "feat(scope): description" --body "..."

# Apply a label only if the repo uses them
gh pr edit <pr-number> --add-label "<repo-label>"
```
