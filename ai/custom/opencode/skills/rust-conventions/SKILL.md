---
name: rust-conventions
description: "Trigger: writing or reviewing Rust — .rs files, Cargo.toml, cargo check/clippy, ownership, borrow checker, Result/Option. Apply the local Rust conventions."
license: Apache-2.0
metadata:
  author: iperez
  version: "1.0"
---

- All Rust code must compile successfully with `cargo check`.
- Code must follow idiomatic Rust style and conventions.
- Prefer using Rust language features and standard library facilities instead of manual or workaround-based solutions.
- Use ownership, borrowing, lifetimes, enums, pattern matching, and error handling (`Result`, `Option`) idiomatically.
- Avoid writing “C-style” or “Java-style” Rust when safer or more expressive Rust patterns exist.
- If unsure about the idiomatic approach, state the uncertainty explicitly instead of guessing.
