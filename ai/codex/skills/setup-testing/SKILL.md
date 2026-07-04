---
name: setup-testing
description: "Discover and prepare SDD testing prerequisites for Playwright, Maestro, browsers, and devices in a system-agnostic, user-guided way. Trigger: setup testing or missing testing prerequisites."
license: Apache-2.0
metadata:
  author: iperez
  version: "1.1"
---

## When to Use

Run this skill when:

- The user asks to set up the testing environment (`setup testing`, `install testing dependencies`, `preparar el entorno de testing`).
- The testing pipeline (`explore-testing`, `plan-testing`, `run-testing`) detects missing prerequisites and proposes setup before continuing.
- A fresh clone or a new machine needs to become test-ready.

Do NOT run this skill for: test execution, test planning, or fixing test failures unrelated to missing tools.

## Operating Principles

- **Discover first.** Identify OS, shell, package managers, existing tools, connected devices, and repo hints before proposing any action.
- **Stay system-agnostic.** Support Linux, macOS, Windows, and WSL. Do NOT assume Homebrew, apt, winget, npm, Android Studio, Xcode, or any specific package manager is available.
- **Ask before heavy actions.** Always get confirmation before installs, SDK downloads, accepting Android licenses, creating AVDs/simulators, using cloud devices, or writing repo files.
- **Keep source safe.** Do NOT edit application source. Only write testing support files when the user explicitly approved that scope.

## Detection Phase

Before proposing any action, detect current state inline:

1. Detect platform and shell context:
   - Linux / macOS / Windows / WSL
   - available shells / terminals
   - available package managers or installers (if any)
2. Check repo hints:
   - `TESTING_SETUP.md`
   - `.maestro/` directory or existing `*.yaml` flows
   - `package.json` / lockfiles / existing test scripts
   - `.mcp.json` or other MCP configuration files if present
3. Check Playwright readiness:
   - `@playwright/test` in `package.json` devDependencies when applicable
   - `npx playwright --version`
   - `npx playwright install --dry-run`
4. Check Maestro readiness:
   - `maestro --version`
   - whether the runtime exposes Maestro MCP helpers (`list_devices`, `run`, etc.)
   - existing `.maestro/**/*.yaml` flows
5. Check browser / web-surface readiness when Playwright or Maestro web validation matters:
   - `command -v google-chrome || command -v chromium || command -v chrome`
   - any repo-documented browser launch command or approved web target for Maestro
6. Check device tooling when Maestro is relevant:
   - `adb devices`
   - `emulator -list-avds` when Android emulator tooling exists
   - `xcrun simctl list devices` on macOS when Xcode tools exist
   - user-configured cloud device provider only if already present in repo docs or environment
7. Check app targets when mobile is relevant:
   - `appId`, bundle ID, app path, or launch command from `TESTING_SETUP.md`
   - obvious repo hints (e.g. AndroidManifest / Info.plist / app config) without inventing values

If a command is unavailable on the current OS, record that as a discovery, not as a failure.

## Summary and Confirmation

After detection, report what is present, what is missing, and what setup options are possible on this machine. Use plain language and group the result by engine / surface:

- Playwright (package + browser binaries)
- Maestro (CLI + MCP helpers + flows)
- Browser / web-surface path
- Devices / simulators / emulators
- App targets / credentials / env vars

Then ask what the user wants to do next. Example:

> "Para el pipeline de testing veo esto:
> - Playwright: instalado, pero faltan binarios de WebKit
> - Maestro: CLI no encontrado; tampoco veo helpers MCP activos
> - Browser / web target: no veo un navegador Chromium listo para la ruta visual
> - Android: `adb` está, pero no hay ningún device conectado
> - iOS: no aplica en esta máquina
>
> Puedo preparar Playwright, instalar Maestro, o dejarlo en best-effort. Antes de instalar nada pesado, aceptar licencias, crear emuladores, o escribir archivos del repo, te pregunto. ¿Cómo querés seguir?"

There is **no default yes** for installs or provisioning. Wait for the user's explicit approval.

## Execution

After confirmation, do the smallest approved setup only.

- **Playwright**
  - Install the package only if repo writes are approved.
  - Install browser binaries only if the user approved the download.
- **Maestro**
  - Install or upgrade the CLI using the user's approved toolchain.
  - If Maestro MCP configuration is missing and the user approved repo/config writes, add or update it.
  - Do NOT assume a package manager; if none is available, provide manual install steps instead of guessing.
- **Devices / simulators / emulators**
  - Ask before downloading SDK components, accepting Android licenses, creating AVDs, booting emulators, creating iOS simulators, or using cloud devices.
  - If the user says no, stop at discovery and report the remaining gap.
- **Repo files / flows**
  - Ask before writing `.maestro/**/*.yaml`, `.mcp.json`, or other repo files.
  - Prefer repo-provided setup scripts only when they exist, their actions match the approved scope, and the user approved running them.

## After Completion

Report exactly what changed and what still needs manual action. Always call out:

- remaining credentials / env vars still missing
- whether Playwright browser binaries were installed
- whether Maestro CLI and MCP helpers are ready
- whether any device / simulator / emulator still needs the user to connect, start, or approve it
- whether any browser / web target still needs a manual start, login, or approval step

If the user chose not to install or provision something, say so explicitly rather than implying setup is complete.

## Engram Save

After a successful run, save to engram:

```text
mem_save(
  title: "Setup testing completed",
  type: "config",
  topic_key: "testing/{project}/setup-state",
  content: "What was installed, what was skipped, what requires manual action."
)
```
