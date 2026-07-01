# Testing Setup

Technical setup for running tests in this project. For product context and business rules
that affect how to interpret results, see `TESTING_CONTEXT.md`.

Keep this file updated when the stack, test runner, or environments change.

---

## Testing Modes Available

Mark which modes are supported. The testing pipeline uses this when selecting modes.

- [ ] `browser` — end-to-end browser tests
  - [ ] `playwright` — Playwright CLI, headless or headed, cross-browser. Specs location: `<path>`
  - [ ] `chrome-extension` — Claude Chrome extension drives a real Chrome session
- [ ] `backend` — unit / integration tests via a test runner
- [ ] `api` — HTTP/API tests without a browser (curl, supertest, Postman, etc.)

---

## Run Commands

```bash
# Install dependencies
<command — e.g. npm install>

# Browser tests (Playwright)
<command — e.g. npx playwright test>

# Backend tests
<command — e.g. npm test, pytest, go test ./...>

# API tests
<command — e.g. npm run test:api>
```

Playwright config: `<path to playwright.config.ts>`

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

Special auth flows: `<MFA, SSO, or role-based login quirks if any>`

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

| Name | URL | Notes |
|------|-----|-------|
| Local | `<http://localhost:PORT>` | Run `<start command>` first |
| Staging | `<URL>` | Deployed from `<branch>` |
| Preview | `<URL pattern>` | Per-PR — `<how to find the URL>` |

Default environment: `<local / staging / preview>`

Override with: `<BASE_URL or equivalent env var>`

---

## Cross-Browser Support

| Browser | Supported | Known Issues |
|---------|-----------|--------------|
| Chromium | `<yes/no>` | |
| Firefox | `<yes/no>` | |
| WebKit (Safari) | `<yes/no>` | |

Mobile viewports: `<yes / no / partial>`

---

## Known Flaky Areas

Areas historically unreliable in tests (the runner/test, not necessarily a product bug). Check
these first when a test fails unexpectedly.

- `<area>`: `<why it's flaky and what to watch for>`
- `<area>`: `<why it's flaky and what to watch for>`
