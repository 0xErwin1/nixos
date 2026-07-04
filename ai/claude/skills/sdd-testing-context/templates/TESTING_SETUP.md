# Testing Setup

Technical setup for running tests in this project. For product context and business rules
that affect how to interpret results, see `TESTING_CONTEXT.md`.

Keep this file updated when the stack, test runner, environments, or supported devices change.

---

## Testing Modes Available

Mark which modes are supported. The testing pipeline uses this when selecting modes.

- [ ] `browser` — end-to-end browser tests
  - [ ] `playwright` — Playwright CLI, headless or headed, cross-browser. Specs location: `<path>`
  - [ ] `chrome-extension` — Claude Chrome extension drives a real Chrome session
  - [ ] `maestro` — Maestro drives a web/Chromium flow. Flows location: `<path>`
- [ ] `mobile` — Android / iOS / hybrid / device-first flows
  - [ ] `maestro` — Maestro CLI / MCP. Flows location: `<path — e.g. .maestro/>`
- [ ] `backend` — unit / integration tests via a test runner
- [ ] `api` — HTTP/API tests without a browser (curl, supertest, Postman, etc.)

---

## Run Commands

```bash
# Install dependencies
<command — e.g. npm install>

# Browser tests (Playwright)
<command — e.g. npx playwright test>

# Browser / mobile tests (Maestro)
<command — e.g. maestro test .maestro/smoke.yaml>

# Backend tests
<command — e.g. npm test, pytest, go test ./...>

# API tests
<command — e.g. npm run test:api>
```

Playwright config: `<path to playwright.config.ts>`

Maestro flows location: `<path — e.g. .maestro/>`

Backend test framework: `<jest / vitest / pytest / go test / other>`

---

## Authentication

- Test user email env var: `<TEST_USER_EMAIL or equivalent>`
- Test user password env var: `<TEST_USER_PASSWORD or equivalent>`
- Auth method: `<email+password / OAuth / magic link / API token / other>`

> Never hardcode credentials. Reference them only via environment variables.

```bash
cp .env.example .env.test
```

Special auth flows: `<MFA, SSO, role-based login quirks, device login notes if any>`

---

## Maestro Targets

- Supported surfaces: `<android / ios / web / mixed>`
- Android appId / package name: `<com.example.app>`
- iOS bundle ID: `<com.example.app>`
- Web target / base URL for Maestro: `<https://...>`
- Preferred devices / emulators / simulators: `<device names or profiles>`
- Device discovery command: `<list_devices / adb devices / xcrun simctl list devices / cloud provider>`
- Launch command or build artifact (optional): `<how to open/install the app when needed>`
- Persisted `.maestro/**/*.yaml` flows allowed: `<yes / no / ask first>`

---

## Test Data

```bash
# Seed database
<command — e.g. npm run db:seed:test>

# Reset to clean state
<command — e.g. npm run db:reset:test>
```

Fixtures location: `<path — e.g. tests/fixtures/>`

---

## Environments

| Name | URL / Target | Notes |
|------|--------------|-------|
| Local | `<http://localhost:PORT>` | Run `<start command>` first |
| Staging | `<URL>` | Deployed from `<branch>` |
| Preview | `<URL pattern>` | Per-PR — `<how to find the URL>` |
| Mobile build | `<apk / app / deep link / store build>` | `<how to install or open it>` |

Default environment: `<local / staging / preview / mobile build>`

Override with: `<BASE_URL or equivalent env var>`

---

## Cross-Browser / Device Support

| Surface | Supported | Known Issues |
|---------|-----------|--------------|
| Chromium | `<yes/no>` | |
| Firefox | `<yes/no>` | |
| WebKit (Safari) | `<yes/no>` | |
| Android device / emulator | `<yes/no>` | |
| iOS simulator / device | `<yes/no>` | |

Mobile viewports: `<yes / no / partial>`

---

## Visual Evidence

- Browser screenshot location (temp only): `<path or command>`
- Maestro screenshot / hierarchy evidence: `<viewer / temp dir / attachment flow>`
- Notes on what must stay out of the repo: `<screenshots, creds, temp captures, etc.>`

---

## Known Flaky Areas

Areas historically unreliable in tests (the runner/test, not necessarily a product bug). Check
these first when a test fails unexpectedly.

- `<area>`: `<why it's flaky and what to watch for>`
- `<area>`: `<why it's flaky and what to watch for>`
