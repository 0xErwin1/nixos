---
name: visual-diff
description: "Compare a design reference (Figma, Zeplin, XD, screenshot, URL) against a live web or mobile UI via structured checklist. Trigger: visual diff in sdd-run-testing."
license: Apache-2.0
metadata:
  author: iperez
  version: "0.2-draft"
---

> NOTE: This skill is DRAFT. The checklist approach and output format are defined here, but the
> implementation inside `sdd-run-testing` is still best-effort. The agent follows this spec to the
> extent that available tools allow. Actual automation depth depends on the active engine and tools.

## Engine Compatibility

Visual diff works with all supported UI engines:

- `playwright` — browser DOM + screenshots, best for cross-browser verification
- `maestro` — Android / iOS / web/Chromium screenshots and screen hierarchy, best for device-first validation

Cross-browser visual coverage (Chromium + Firefox + WebKit) still requires `engine: playwright`.
`engine: maestro` is the device / Chromium path for browser or mobile validation.

## When to Use

Apply this skill in `sdd-run-testing` when:

- The test plan marks a test case as `visual diff: yes`.
- A design reference is available in the plan or in `TESTING_CONTEXT.md`.

A design reference can be any of: a Figma frame URL or node ID, a Zeplin share link, an Adobe XD link, a Sketch Cloud URL, a screenshot file path, or any URL that renders the intended design.

Skip visual diff if:

- No design reference is available.
- The screen has highly dynamic content (charts, live feeds, user-generated content) where structural comparison is not meaningful.

## Pass/Fail Criterion

Use the structured checklist as the pass/fail criterion. Pixel diff screenshots are saved as informative artifacts only — they MUST NOT gate pass/fail.

## Structured Checklist Approach

### Step 1 — Extract design specs from the reference

Use the best available method for the reference type:

- **Figma URL or node ID**: use the Figma MCP (`mcp__plugin_figma_figma__*` or equivalent) if connected. If the MCP is absent, fetch the Figma share URL with `WebFetch` and extract any readable spec.
- **Zeplin / Adobe XD / other share URL**: fetch with `WebFetch` and parse visible spec annotations (font, color, spacing values shown in the tool's inspect panel HTML).
- **Screenshot or image file**: read the file directly. Use visual inspection to identify typography, colors, spacing, and layout from the rendered image.
- **Renderable URL**: navigate to it and capture what is visible.

In all cases, extract:

- Typography: font family, size, weight, line height, letter spacing per text element
- Colors: fill and stroke colors per element (hex or design token name)
- Spacing: padding, margin, gap values for key containers
- Layout: flex direction, alignment, column/row counts for grids
- Hierarchy: z-order and nesting of main elements

### Step 2 — Capture live implementation

Navigate to the screen under test, branching on the engine:

- **`engine: playwright`** → navigate and capture via Playwright (`page.evaluate()` for computed styles, screenshot via the CLI).
- **`engine: maestro`** → drive the device or Chromium/web target through Maestro. Prefer Maestro MCP helpers (`inspect_screen`, `take_screenshot`) when available; otherwise fall back to `maestro hierarchy` plus the best screenshot mechanism exposed by the runtime.

Capture (shared between all engines):

- Screenshot (informative only — not pass/fail)
- Computed styles, screen hierarchy, or other inspectable UI properties for the elements that correspond to the design reference

### Step 3 — Build the checklist

For each property extracted in Step 1, create a checklist item:

| Item | Design spec | Observed | Result |
|------|------------|----------|--------|
| `<element> font-size` | `<value>` | `<value>` | `pass / fail / skip` |
| `<element> color` | `<hex>` | `<hex>` | `pass / fail / skip` |
| `<container> padding` | `<value>` | `<value>` | `pass / fail / skip` |
| ... | | | |

Mark an item `skip` when:
- The element is not present in the current state (e.g. empty state vs. populated state).
- The property is not inspectable via computed styles / hierarchy (e.g. blur filters, complex gradients).

### Step 4 — Produce output

Return:

- **Checklist table** (pass/fail/skip per item)
- **Summary**: X pass, Y fail, Z skip
- **Informative screenshot / evidence** — persistence depends on the persona engine (the screenshot is informative-only and never gates pass/fail):
  - `playwright (code)`: save to a temporary directory outside the repo (e.g. `/tmp/sdd-testing/{feature}/screenshots/`) and reference the path.
  - `maestro (visual device)`: prefer Maestro screenshots / hierarchy attached to the run artifact or saved to a temporary directory outside the repo. `.maestro/**/*.yaml` is the only repo-backed Maestro artifact, and only when the persona explicitly allows persisted flows.
- **Verdict**: `pass` (all non-skip items pass) | `fail` (any item fails) | `partial` (skips present)

## What to Check vs. What to Skip

Check:

- Typography properties for headings, labels, body text
- Brand colors on primary actions (buttons, links, CTAs)
- Spacing on key containers (cards, modals, forms)
- Layout direction and alignment for primary sections

Do NOT check:

- Pixel-exact positions of dynamic content
- Shadow and blur values (too variable across browsers / devices)
- Animation timing
- Content that varies by user or session (avatars, names, dates)

## Integration with `sdd-run-testing`

The `sdd-run-testing` agent calls this skill's logic inline. It does not invoke a sub-agent.
The agent reads this file, applies the checklist methodology, and includes the checklist output
in the run artifact that `sdd-report-testing` reads.

> NOTE: When no MCP or tool can extract specs from the design reference, the agent falls back to visual inspection from a screenshot or rendered URL. If no reference is accessible at all, note the gap in the run artifact and skip visual diff for that test case. It MUST NOT fail the entire run.
