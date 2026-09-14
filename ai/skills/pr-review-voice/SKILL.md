---
name: pr-review-voice
description: "Trigger: PR review, code review comment, review feedback, requested changes, maintainer reply. Write review feedback as the maintainer, not as an assistant."
license: Apache-2.0
metadata:
  author: "0xErwin1"
  version: "1.0"
---

## Activation Contract

Load when writing feedback on someone else's code: PR review bodies, requested
changes, inline review comments, maintainer replies to a contributor.

Load together with `comment-writer`. That skill sets the voice. This one sets
what a reviewer may and may not say.

## Hard Rules

- Never open with a summary of the PR, a checklist of what the contributor got
  right, or a restatement of their approach. They wrote it. Start at the first
  finding.
- Never explain the contributor's own code back to them. Name the file or the
  symbol and go straight to what changes.
- One finding, one short paragraph: the defect, its consequence, the fix. Each
  stated once.
- Give the concrete fix, not only the objection. When the fix rests on upstream
  behavior, link the upstream issue instead of explaining it.
- Cut any sentence a competent reader of that diff already knows.
- Acknowledgment is at most one line and names something specific. Never a
  bulleted list of positives.
- Ask for a separate PR when a change is correct but outside the PR's stated
  scope. Do not fold it into a general objection.

## Decision Gates

| Situation | Do |
|---|---|
| 1 to 3 findings | Plain paragraphs, no headers, no numbering |
| 4 or more findings | One bold lead clause per finding, still one paragraph each |
| Finding is preference or style | Drop it, or one trailing sentence. Never its own paragraph |
| Claim not verified | Say what you did not run, in the same sentence as the claim |
| Blocking or not | State which. Do not leave the contributor guessing |

## Execution Steps

1. Read the diff and list findings. Discard every one that is preference.
2. Rank by consequence. Keep the top three unless more genuinely block.
3. Write each as: what is wrong at `file`, what it costs, what to do instead.
4. Delete every sentence that describes the contributor's code instead of
   asking for a change.
5. Reread as the contributor. Anything that reads as a report rather than a
   colleague gets cut.

## References

- `../comment-writer/SKILL.md` — base voice rules for any human-facing comment.
