---
name: issue-creation
description: "Create issues that follow the repo's own conventions. Trigger: creating GitHub issues, bug reports, or feature requests."
license: Apache-2.0
metadata:
  author: iperez
  version: "2.1"
---

## When to Use

Use this skill when:
- Creating a GitHub issue (bug report or feature request)
- Helping a contributor file an issue
- Triaging issues as a maintainer

---

## Core Principle

**Follow the repository's own conventions.** Do not impose a fixed template, label taxonomy, or approval gate. Before filing an issue, read what the repo actually expects and match it. Approval workflows, specific labels, and required fields apply only when the repo defines them.

---

## Workflow

```
1. Detect the repo's issue conventions (see below)
2. Search existing issues for duplicates
3. Load comment-writer + cognitive-doc-design (see "Writing Style"), then write the body
4. Use the repo's template if one exists; otherwise write a clear, structured issue
5. Fill the fields the template/CONTRIBUTING asks for
6. Apply labels only if the repo maintains a taxonomy
7. Submit
```

---

## Detecting Repo Conventions

Before writing the issue, inspect the repo and adopt what you find:

| Source | What it tells you |
|--------|-------------------|
| `.github/ISSUE_TEMPLATE/` | Available templates, required fields, auto-labels |
| `.github/ISSUE_TEMPLATE/config.yml` | Whether blank issues are disabled; where questions go (Discussions) |
| `CONTRIBUTING.md` | Issue rules, approval workflow, triage process |
| Existing labels (`gh label list`) | Whether a label/status taxonomy exists and which to apply |
| Recent issues (`gh issue list`) | De-facto norms for titles, structure, and labeling |

If the repo enforces a template, an approval label (e.g. `status:approved`), or routes questions to Discussions, comply with it. If it does not, do **not** invent one — file a clean, well-structured issue and stop.

When conventions are absent or unclear, fall back to the defaults below and state what you assumed.

---

## Writing Style (mandatory)

An issue is read by other people, so its style is not freeform. Before writing a single line of the title or body, load BOTH writing skills in the current turn and apply them together:

- **`cognitive-doc-design`** — shapes the BODY so a maintainer can scan and act fast: lead with the answer (what is wrong / what is wanted, first), chunk the sections, prefer tables and numbered steps over dense prose, signpost with the template's headings.
- **`comment-writer`** — shapes the VOICE of every prose sentence: warm and direct, useful fast, explain the why behind a request, no filler. It also governs any follow-up replies you post on the issue thread.

Resolve the two skills' guidance into one consistent style: structured and scannable (doc design) AND warm and direct (comment voice). They do not conflict — doc-design owns layout, comment-writer owns tone.

**Language:** write the issue in the destination repository's primary language, not the chat language — English when the repo is English, even if we are talking in Spanish. `comment-writer` carries the full language rule; defer to it.

Self-check before submitting: "Did I load both writing skills this turn, and does the issue read as scannable AND warmly direct?" If not, stop and apply them.

---

## Default Issue Structure

If the repo has no template, write the issue with a clear structure appropriate to its kind.

### Bug report (default)

- **Description** — what's wrong, in one or two sentences.
- **Steps to reproduce** — numbered, minimal.
- **Expected behavior** — what should happen.
- **Actual behavior** — what happens, with errors/logs.
- **Environment** — OS, tool/client, shell, versions — whatever is relevant.

### Feature request (default)

- **Problem** — the pain point this solves.
- **Proposed solution** — how it should work from the user's perspective.
- **Alternatives considered** — other approaches or workarounds (optional).

Always search for duplicates first and link any related issue.

---

## Labels and Approval

Apply these only when the repo defines them:

- **Type/status labels** (`bug`, `enhancement`, `status:needs-review`, etc.) — use the repo's taxonomy; many templates auto-apply them.
- **Approval gate** (`status:approved` or similar) — respect it only if CONTRIBUTING or CI enforces an issue-first workflow. Do not assume one exists.
- **Priority labels** — apply only as a maintainer following the repo's process.

If the repo has no label system, do not add labels.

---

## Commands

```bash
# Inspect conventions first
ls .github/ISSUE_TEMPLATE/ 2>/dev/null
gh label list 2>/dev/null
gh issue list --limit 5

# Search for duplicates before creating
gh issue list --search "keyword"

# Create with a repo template (if one exists)
gh issue create --template "bug_report.yml" --title "fix(scope): description"

# Create without a template (no template defined)
gh issue create --title "fix(scope): description" --body "..."

# Apply a label only if the repo uses them
gh issue edit <number> --add-label "<repo-label>"
```
