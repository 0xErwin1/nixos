---
name: maestro-mobile-testing
description: "Trigger: Maestro, mobile E2E, React Native, Expo, YAML flows, flaky tests, auth, optimistic updates, CI, MCP device testing. Build reliable Maestro flows."
license: MIT
metadata:
  author: tovimx
  version: "1.1.0"
---

## Activation Contract

Load for Maestro mobile E2E work in React Native or Expo: creating or reviewing YAML flows, diagnosing flaky tests, validating auth or optimistic updates, configuring CI, or MCP-driven device inspection/execution.

## Hard Rules

- Load `references/upstream-guide.md` before selecting detailed Maestro patterns or commands.
- Prefer stable `testID` selectors and Maestro waiting/assertion primitives; do not mask timing defects with arbitrary sleeps.
- Never embed credentials, tokens, or test accounts. Do not blindly run upstream curl or brew installation commands in this Nix-managed harness.
- Treat repo-backed `.maestro/**/*.yaml` creation or edits as writes requiring user approval or the current workflow's explicit write permission.

## Decision Gates

| Condition | Action |
| --- | --- |
| Installed Maestro MCP is available | It may inspect and execute against the live device; confirm target state before mutations. |
| Auth or backend-dependent flow | Use the upstream adaptive auth and mock/API patterns; isolate state. |
| Flaky or optimistic-update flow | Capture observable pre/post conditions, then use retry-safe assertions and diagnostics. |
| CI or cross-platform target | Follow upstream CI, platform, and Cloud guidance; report environment limits. |

## Execution Steps

1. Read the upstream guide and inspect the app, existing `.maestro` flows, selectors, and permitted device tooling.
2. Define the smallest YAML flow with explicit app state, stable selectors, and assertions for the user-visible outcome.
3. When authorized, run or inspect with Maestro or its installed MCP; reproduce failures before changing flow logic.
4. Keep reusable subflows, auth handling, mock dependencies, screenshots, and CI configuration aligned with the upstream patterns.

## Output Contract

Return the flow path or proposed YAML, target platform/device, commands or MCP actions run, assertions and observed result, flake/auth/optimistic-state handling, and any blocked permission or environment requirement.

## References

- [references/upstream-guide.md](references/upstream-guide.md) — complete verbatim upstream Maestro guide, including YAML, auth, stability, CI, Cloud, and MCP patterns.
