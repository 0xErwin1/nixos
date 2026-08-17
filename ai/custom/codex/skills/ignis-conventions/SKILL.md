---
name: ignis-conventions
description: "Trigger: writing or reviewing Ignis — .ign files, Ignis modules, structs, records, enums. Apply the local Ignis naming and semantics rules."
license: Apache-2.0
metadata:
  author: iperez
  version: "1.0"
---

#### Naming conventions

- Use `camelCase` for variables, functions, parameters, fields, and methods.
- Use `UPPER_SNAKE_CASE` for constants and enum members.
- Use `PascalCase` for:
  - Modules / namespaces
  - External namespaces
  - Structs
  - Records
  - Enums
  - Type definitions
- Do not mix naming styles within the same construct or scope.

#### Language semantics

- Do not assume Ignis behaves like Rust, TypeScript, or any other language.
- Do not infer features or semantics by analogy.
- Always rely on the Ignis documentation or the provided codebase as the source of truth.
- If a language feature or behavior is unclear or undocumented, state the uncertainty explicitly instead of guessing.
