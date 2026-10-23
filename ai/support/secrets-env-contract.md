# AI Harness Secrets Env-File Contract

Home Manager may reference secret locations, but it must not own secret values.

## External files

Create these files outside Git before switching:

- `/home/iperez/.config/ai-harness/secrets/mcp.env`
- `/home/iperez/.config/ai-harness/secrets/api.env`

The files are machine-local and should be mode `600`. Validation never opens or prints their contents; it only checks that the files exist. A missing file aborts activation before the write boundary (`gentleAiSecretsPreflight` in `home-manager/global/ai.nix`).

## File format and consumption

Each file is a shell env file of `export VAR=value` lines. At activation, Gentle AI resolves every `@VAR@` placeholder in the paths listed under `programs.gentle-ai.secrets` from these files. Placeholders live in Git; resolved values exist only in the written files, never in the Nix store.

### Required variables

`mcp.env` must provide every placeholder the declared MCP servers use:

- `CONTEXT7_API_KEY` — Context7 MCP API key
- `PENPOT_API_KEY` — Penpot MCP user token
- `CLAUDE_ATLAS_TOKEN` — Atlas MCP token for every client except Pi
- `PI_ATLAS_TOKEN` — Atlas MCP token for Pi

`api.env` may be empty; it only needs to exist for the preflight.

## Validation contract

Readiness checks must inspect only managed source files and Nix-generated activation text. They may verify that the external paths are named and that missing files produce a clear message, but they must not open or print local credential files.
