---
description: Deslop is a tool designed to remove AI-generated slop from code.
agent: build
---

# Remove AI-generated slop (without destroying real docs)

Review the changes in the current working set (prefer STAGED changes; otherwise compare the working tree to HEAD).
Your goal is to make the patch feel human and consistent with the repo style.

## Non-negotiables (do not break docs)
- **Do NOT delete documentation comments** or large doc blocks.
  - You may *lightly edit* doc comments for clarity/conciseness **only if** they are clearly redundant or incorrect.
  - Preserve **examples**, **fenced code blocks** (```), **tables**, and **ASCII diagrams** inside doc comments when they explain behavior, safety, layout, or usage.
- Regular comments (`//`, `/* */`) are fair game.

## How to identify “slop”
“Slop” is not formatting or length. Slop is:
- Generic filler (“robust”, “comprehensive”, “seamless”, “powerful”, “designed to”, etc.)
- Repeating what the code already says without adding invariants, edge cases, or rationale
- Over-explaining obvious control flow
- Marketing tone, hedging, or boilerplate disclaimers that provide no actionable info

## What to keep (even if long)
Keep comments (including long ones) when they provide:
- Invariants / safety contracts / UB conditions
- Non-obvious reasoning (“why this choice”)
- Tricky edge cases (overlap, lifetime, aliasing, alignment, ownership rules)
- Usage examples that clarify correct calling patterns
- Architecture diagrams and “mental model” docs (ASCII art is OK)

## What to fix
- Overly defensive checks/validations that don’t match existing patterns (especially in trusted/validated paths)
- Type “band-aids” (any, unsafe casts, double casts, ignore directives) — fix the root cause where practical
- Boilerplate wrappers/abstractions that add indirection without clear value
- Long or “essay-like” identifiers — rename to concise, idiomatic names consistent with the codebase
- Refactors that change structure without improving readability, correctness, or performance — revert or simplify

## Logging
- Keep logs that add operational value (actionable context, clear intent).
- Remove logs that are noisy, redundant, or uninformative.

## Safety
- Do not change behavior unless it’s clearly a bug fix.
- Do not introduce new dependencies.
- Do not run commands or modify git history without explicit permission.

## Output
- Provide the updated patch.
- Then give a 1–3 sentence summary of the improvements.
