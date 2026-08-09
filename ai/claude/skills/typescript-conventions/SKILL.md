---
name: typescript-conventions
description: "Trigger: writing or reviewing TypeScript or JavaScript — .ts, .tsx, .js, .jsx, .mjs, tsconfig, eslint, Node backends, promises, nullability. Apply the local TS/JS conventions."
license: Apache-2.0
metadata:
  author: iperez
  version: "1.0"
---

- Do not assume runtime behavior; distinguish clearly between type-level and runtime-level logic.
- Prefer reading existing project conventions (tsconfig, eslint/prettier, existing patterns) before introducing new ones.
- Avoid breaking changes to public APIs unless explicitly requested.

#### TypeScript correctness

- Prefer type-safe solutions; avoid `any` and `unknown` casts unless strictly necessary.
- Do not use `as any` or double casts like `as unknown as T` unless there is no viable alternative; if used, justify why and contain it locally.
- Prefer narrow types and explicit return types for public functions.
- If a function accepts or returns `Promise`, ensure it is actually async-safe with no swallowed errors and no unhandled rejections.

#### Nullability & narrowing

- Handle `null` and `undefined` explicitly; do not rely on truthiness checks when the value can be `0`, `""`, or `false`.
- Prefer type guards and early returns for narrowing.
- Avoid non-null assertion (`!`) unless you can prove the invariant; if used, explain the invariant.

#### Async & Promises

- Use `await` for promise chains where readability improves; avoid deeply nested `.then()`.
- Do not forget to `await` async calls inside `try/catch` when error handling matters.
- Avoid `forEach(async () => ...)`; use `for...of` or `Promise.all` depending on concurrency needs.
- When using `Promise.all`, consider failure semantics and call out whether fail-fast is acceptable.

#### Error handling

- Throw `Error` objects or subclasses, not strings.
- Preserve error context by wrapping errors with `cause` or relevant identifiers.
- Do not swallow errors silently; if a failure is intentionally ignored, state why.

#### Modules & imports

- Use ESM or CJS consistently with the repository; do not mix unless the project already does.
- Prefer explicit imports; avoid wildcard imports unless necessary.
- Keep exports stable; avoid reorganizing module boundaries unless requested.

#### Node.js / backend practices (when applicable)

- Prefer structured logging patterns already used in the codebase; do not log secrets.
- Validate external input at boundaries such as HTTP handlers, queues, or DB reads rather than deep in business logic.
- Prefer parameterized queries or safe query builders; avoid string concatenation for SQL.
