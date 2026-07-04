---
name: sdd-testing-context
description: "Bootstrap or update testing context files at the repo root. Trigger: set up or refresh TESTING_CONTEXT/TESTING_SETUP when the stack or product changes."
license: Apache-2.0
metadata:
  author: iperez
  version: "1.2"
---

## When to Use

Run this skill when:

- Setting up a repo for the first time.
- The stack has changed (new auth flow, new Playwright config location, new Maestro device flow, new environments).
- Product behavior or business rules have changed and testers need to know.
- The test pipeline is reporting missing-context warnings.

The testing pipeline reads the output files if present but does not require them.

## Output Files (all at repo root)

| File | Required | Description |
|------|----------|-------------|
| `TESTING_CONTEXT.md` | Generated always | Product and business context: constraints, business rules, known quirks, design references |
| `TESTING_SETUP.md` | Generated always | Technical setup: how to run tests, auth, environments, Playwright / Maestro / device notes, test data, known flaky areas |
| `ARCHITECTURE.md` | Optional — ask before generating | System overview for non-technical readers |
| `GLOSSARY.md` | Optional — ask before generating | Domain terms, user roles, internal nicknames |

The split is intentional: `TESTING_CONTEXT.md` is for *understanding results* — product constraints, business rules, non-obvious behaviors, and design references. `TESTING_SETUP.md` is for *running tests* — commands, credentials, environments, Playwright / Maestro / device setup, and known flaky areas (operational).

## Workflow

```text
1. Check which files already exist at repo root
2. For each missing file: propose generating it and ask for confirmation
3. For each existing file: show a diff-preview of what would change and ask before overwriting
4. Generate the file using the matching template from this skill's templates/ directory
5. Ask the developer to fill in the <placeholder> sections
```

Never overwrite an existing file without explicit per-turn confirmation from the user.

## Decision Tree

```text
TESTING_CONTEXT.md exists?
  No  → Generate it (always offer)
  Yes → Show existing content summary, ask if update is needed

TESTING_SETUP.md exists?
  No  → Generate it (always offer)
  Yes → Show existing content summary, ask if update is needed

ARCHITECTURE.md exists?
  No  → Ask: "Do you want an ARCHITECTURE.md for the testing pipeline?"
  Yes → Show existing content summary, ask if update is needed

GLOSSARY.md exists?
  No  → Ask: "Do you want a GLOSSARY.md with domain terms?"
  Yes → Show existing content summary, ask if update is needed
```

## Template Locations

Templates are under `templates/` relative to this skill directory:

- `templates/TESTING_CONTEXT.md`
- `templates/TESTING_SETUP.md`
- `templates/ARCHITECTURE.md`
- `templates/GLOSSARY.md`

Read the matching template, then fill in what can be inferred from the codebase automatically.
Leave `<placeholder>` text for values that require developer knowledge.

## What to Auto-Detect

When generating `TESTING_SETUP.md`, scan the repo to auto-fill:

- `playwright.config.*` location
- Playwright / backend / API test script names from `package.json` scripts
- `.maestro/` flow locations and any existing Maestro YAML files
- `.env.example` or `.env.test` for env var names (never log values)
- framework detection (Next.js, Rails, Django, React Native, Expo, etc.) for test command hints
- `package.json` dependencies for test libraries (`vitest`, `jest`, `playwright`, mobile stacks)
- obvious app identifiers or bundle IDs when native/mobile setup is in repo config (never invent values)

`TESTING_SETUP.md` also carries known flaky areas (operational — unreliable in the test runner/test, not a product concern). Ask the developer to fill these in; they cannot be auto-detected.

When generating `TESTING_CONTEXT.md`, ask the developer to fill in product/why information only: known constraints, non-production areas, business rules affecting tests, role/permission matrix, and design references. Do NOT auto-fill these — they require product knowledge. Flaky areas do NOT belong here — they live in `TESTING_SETUP.md`.

Leave everything else as `<describe X here>` placeholders.

## Commands

```bash
# Check what exists
ls TESTING_CONTEXT.md TESTING_SETUP.md ARCHITECTURE.md GLOSSARY.md 2>/dev/null

# Find Playwright config
find . -name "playwright.config.*" -not -path "*/node_modules/*"

# Find Maestro flows
find . -path "*/node_modules/*" -prune -o -path "*/.git/*" -prune -o -path "./.maestro/*.yaml" -print

# Find test scripts
cat package.json | grep -A8 '"scripts"'
```
