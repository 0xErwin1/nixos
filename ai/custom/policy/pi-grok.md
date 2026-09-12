# Local policy appendix

## Questions and personal notes

- A question does not authorize a mutation. Answer it and wait for explicit approval when the intent is ambiguous.
- Personal working notes stay in the configured external artifact system unless the user explicitly requests repository documentation.

## GitHub CLI

Before any `gh` operation, read `~/.agents/skills/_shared/gh-convention.md`. It is the account and authorization contract. Do not duplicate or infer its account rules here.

## Atlas

Use only the configured Atlas MCP tools. When an Atlas task informs planning, implementation, status, editing, verification, or exact quoting, first retrieve each relevant task with `atlas_get_task` at `detail: "full"`, then obtain useful linked context. Read `~/.agents/skills/_shared/atlas-persistence-contract.md` before Atlas work and follow its current contract.

## External prose

Before drafting external comments, messages, or documentation, load the installed `comment-writer` or `cognitive-doc-design` skill as applicable. For GitHub content, the explicit language contract in `gh-convention.md` overrides generic destination-language guidance.

## Language conventions

Before writing or reviewing Rust, Ignis, or TypeScript/JavaScript, load the available `rust-conventions`, `ignis-conventions`, or `typescript-conventions` skill respectively.
