---
name: setup-testing
description: "Install and verify SDD testing pipeline prerequisites: Playwright, browsers, MCPs. Trigger: setup testing or missing testing prerequisites."
license: Apache-2.0
metadata:
  author: iperez
  version: "1.0"
---

## When to Use

Run this skill when:

- User asks to set up the testing environment ("setup testing", "configurame el entorno de testing",
  "install testing dependencies", "preparar el entorno para tests").
- The testing pipeline (`explore-testing`, `plan-testing`, `run-testing`) detects a missing
  prerequisite and proposes running setup before continuing.
- A fresh clone of the project needs to be made test-ready.

Do NOT run this skill for: test execution, test planning, or fixing test failures unrelated to
missing tools.

## Detection Phase

Before proposing any action, detect current state inline:

```
1. Check package.json exists at cwd
2. Check @playwright/test in package.json devDependencies
3. Run: npx playwright --version 2>/dev/null (exit 0 = installed)
4. Run: npx playwright install --dry-run 2>&1 | grep -i "missing\|not found" (check browser binaries)
5. Check .mcp.json at cwd for the "playwright-mcp" entry. (Do NOT gate on "chrome-devtools-mcp" — the setup script does not register it; no confirmed package. Treat it as pending, not missing.)
6. Check if Claude CLI is available: command -v claude
7. Check for Chrome: command -v google-chrome || command -v chrome || [ -d "/Applications/Google Chrome.app" ]
```

## Summary and Confirmation

After detection, report what is missing in plain language. Example:

> "Para el pipeline de testing faltan:
> - @playwright/test (no está en package.json)
> - Binarios de browsers Playwright (Chromium, Firefox, WebKit)
> - Entrada MCP para playwright-mcp en .mcp.json (Chrome DevTools MCP queda pendiente — sin paquete confirmado)
> - Plugin de Figma en Claude Code
>
> ¿Quiero correr el setup ahora? Va a instalar estas dependencias y registrar los MCPs."

Default answer: **yes**. If the user says yes (or `--yes` mode), proceed. If no, stop.

If everything is already installed, report: "Todo está instalado. No hay nada que hacer."

## Execution

Call the setup script with flags derived from what is missing:

```bash
./scripts/setup-testing.sh [--yes] [--skip-playwright] [--skip-mcp] [--skip-plugins]
```

Pass `--yes` when the user already confirmed in the conversation (avoid double-prompting).

Pass `--skip-playwright` when Playwright and all browser binaries are confirmed present.
Pass `--skip-mcp` when the `playwright-mcp` entry is already in .mcp.json. (Chrome DevTools MCP is not auto-registered and must NOT be part of this condition — otherwise the step would re-run forever.)
Pass `--skip-plugins` when both plugins are already installed.

The script path is relative to the project root where `install.sh` installed the kit. If the
script is not found at `./scripts/setup-testing.sh`, try `.claude/scripts/setup-testing.sh`.

## After Completion

Report what was installed and what (if anything) needs manual action. Always include:

- Chrome extension manual install note if Chrome was detected but the extension status is unknown:
  "Instalá la extensión de Claude para Chrome desde:
  https://chromewebstore.google.com/detail/claude-for-chrome/[extension-id]
  (abrí Chrome y andá a ese link para instalarla)"

> NOTE: The exact Chrome Web Store URL for the official Claude Chrome extension must be verified.
> The extension is maintained by Anthropic; search "Claude for Chrome" in the Chrome Web Store
> if the URL above is incorrect. The skill author could not confirm the exact extension ID at
> authoring time.

## Engram Save

After a successful run, save to engram:

```
mem_save(
  title: "Setup testing completed",
  type: "config",
  topic_key: "testing/{project}/setup-state",
  content: "What was installed, what was skipped, what requires manual action."
)
```
