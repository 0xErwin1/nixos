# Architecture Overview

This file gives the testing pipeline enough context to understand what is being tested and why.
It is intentionally brief — this is not a full architecture spec.

---

## System Overview

`<One or two paragraphs describing what this product does, who uses it, and what problem it solves.>`

---

## Main Components

| Component | Responsibility | Tech |
|-----------|---------------|------|
| `<Frontend app>` | `<what it does>` | `<React / Next.js / Vue / other>` |
| `<Backend API>` | `<what it does>` | `<Node / Rails / Django / Go / other>` |
| `<Database>` | `<what it stores>` | `<PostgreSQL / MySQL / DynamoDB / other>` |
| `<Auth service>` | `<how auth works>` | `<Auth0 / Supabase / custom / other>` |
| `<Other>` | `<describe>` | `<tech>` |

---

## Key Data Flows

Describe the flows that matter most for testing — what happens when a user does X.

### `<Flow name — e.g. User submits a form>`

```
<Step 1 — e.g. User fills form in React component>
  → <Step 2 — e.g. POST /api/resource>
    → <Step 3 — e.g. Validated by backend, written to DB>
      → <Step 4 — e.g. Response returned, UI updates>
```

### `<Flow name>`

`<describe>`

---

## External Integrations

| Integration | Purpose | How it appears in tests |
|-------------|---------|------------------------|
| `<Service>` | `<what it does>` | `<mocked / real / stubbed>` |
| `<Service>` | `<what it does>` | `<mocked / real / stubbed>` |

---

## Tech Stack Summary

| Layer | Technology | Version |
|-------|-----------|---------|
| Frontend | `<e.g. Next.js>` | `<version>` |
| Backend | `<e.g. Node / Express>` | `<version>` |
| Database | `<e.g. PostgreSQL>` | `<version>` |
| Test runner | `<e.g. Playwright>` | `<version>` |
| CI | `<e.g. GitHub Actions>` | — |
| Hosting | `<e.g. AWS / Vercel / Render>` | — |
