# Testing Context

Product and business context that testers need to make sense of what they see. This is NOT a
how-to-run guide — for commands, auth, and environments see `TESTING_SETUP.md`.

Keep this file updated when product behavior, business rules, or known constraints change.

---

## Known Constraints and Quirks

Things that look wrong but are intentional. Testers should not file bugs for these.

| Screen / Feature | What you see | Why |
|-----------------|-------------|-----|
| `<screen name>` | `<observed behavior>` | `<business reason, technical limitation, or design decision>` |

---

## Non-Production Areas

Sections of the app that are not production-ready. Tests in these areas may be unreliable or
reflect incomplete states.

- `<Feature or screen>`: `<what state it is in and what this means for testers>`

---

## Business Rules Affecting Tests

Rules that determine what is a pass vs a fail — things that are not obvious from the UI alone.

- `<Rule>`: `<how it affects what testers should expect to see>`

---

## Roles and Permissions

How different user roles experience the app. Relevant when testing access control or role-specific flows.

| Role | What they can see / do | Notes |
|------|----------------------|-------|
| `<role name>` | `<description>` | `<edge cases or quirks>` |

---

## Design References

Design files used for visual verification. Any design tool is valid.

| Screen / Feature | Reference | Tool | Notes |
|-----------------|-----------|------|-------|
| `<screen name>` | `<URL, file path, or share link>` | `<Figma / Zeplin / XD / screenshot / other>` | `<frame name or section if applicable>` |

---

## Additional Context

`<Anything else a tester needs to know about the product to interpret test results correctly>`
