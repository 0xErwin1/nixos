# GitHub CLI Contract (gh-convention)

This is the contract for every `gh` / GitHub CLI operation. Unlike the engram convention, these rules are NOT inlined elsewhere -- this file is the source of truth for gh policy. Read it before running any `gh` command.

## When to Apply

Apply this contract before ANY GitHub operation: `gh auth`, PR create/merge/review, issue create/comment, release, repo, or `gh api` calls. It binds the active GitHub account to the working path and gates privileged actions.

## How to Use

### 1. Select the account by working path

Account selection is deterministic, never guessed:

- Working path at or under `~/dev/work/Houlak` (`/home/iperez/dev/work/Houlak`), including all subdirectories -> account `ignaciohoulak`.
- Every other path -> account `0xErwin1`. No exceptions.

### 2. Verify and switch before acting

Before any command that reads from or writes to GitHub:

1. Run `gh auth status` and read the active account.
2. If it differs from the required account, switch with `gh auth switch --user <account>`.
3. If the required account is not authenticated, STOP and ask the user to log in interactively (`! gh auth login`). Never attempt an interactive login yourself and never invent or reuse a token.

### 3. Guard privileged merges

`gh pr merge --admin` bypasses branch protection and required checks. It is privileged:

- ALWAYS stop and ask the user for explicit confirmation before running `gh pr merge --admin`.
- Do NOT use `--admin` to work around failing or pending checks without that approval.

### 4. Language and secrets

- All GitHub content authored through `gh` (PR titles and bodies, issue text, review and reply comments) is written in English. Route the wording through `comment-writer` (comments) and `cognitive-doc-design` (PR/issue bodies and docs).
- Never print, log, or commit tokens. Redact `gho_`, `ghp_`, and `github_pat_` values in any output you surface.

## Decision Table

| Situation | Action |
| --- | --- |
| cwd at or under `~/dev/work/Houlak` | Require account `ignaciohoulak` before running `gh` |
| cwd anywhere else | Require account `0xErwin1` before running `gh` |
| Active account != required account | `gh auth switch --user <required>` before the command |
| Required account not authenticated | STOP; ask the user to run `! gh auth login`; do not proceed |
| `gh pr merge` would need `--admin` | STOP; ask for explicit confirmation; never auto-bypass checks |
| Destructive op (`gh repo delete`, force-push via gh, closing/deleting issues or PRs you did not create) | Confirm with the user first |
| Authoring PR/issue/comment text | Write in English; route wording through the writing skills |

## What to Report

After a gh operation, state:

- The required account and the path rule that selected it.
- Whether a switch was performed.
- For merges, whether `--admin` was requested and the user's confirmation.
- Any blocked action awaiting user input (login, `--admin` approval, destructive confirmation).

## Related

- `comment-writer` -- voice and language for GitHub comments.
- `cognitive-doc-design` -- structure and language for PR and issue bodies.
- `branch-pr` -- PR creation workflow that runs on top of this contract.
