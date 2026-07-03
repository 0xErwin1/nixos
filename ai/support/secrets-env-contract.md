# AI Harness Secrets Env-File Contract

Home Manager may reference secret locations, but it must not own secret values.

## External files

Create these files outside Git before the cutover switch:

- `/home/iperez/.config/ai-harness/secrets/mcp.env`
- `/home/iperez/.config/ai-harness/secrets/api.env`

The files are machine-local and should be mode `600`. Validation never opens or prints their contents; it only checks that the files exist.

## File format and consumption

Each file is a shell env file of `export VAR=value` lines. At activation, Home Manager sources both files and renders every template in `renderedSecretConfigs` (see `home-manager/global/ai-harness.nix`), replacing each `@VAR@` placeholder with the value of the matching environment variable. A placeholder whose variable is unset or empty aborts the switch, so a missing token is caught instead of silently shipped.

Templates live in Git with placeholders only; the rendered files are written outside Git as mutable `600` files (they cannot be read-only Nix-store symlinks, since tokens must reach the final config).

### Required variables

Provide at least the placeholders referenced by the active templates. The MCP
templates for opencode (`ai/opencode/opencode.jsonc`), pi (`ai/pi/mcp.json`),
Claude Code (`ai/claude/mcp-servers.json`), and Codex
(`ai/codex/mcp-servers.toml`) require:

- `ATLAS_TOKEN` — Atlas MCP token
- `CONTEXT7_API_KEY` — Context7 MCP API key

`api.env` may be empty if no `@VAR@` placeholder resolves to it; it only needs to exist for the preflight.

## Managed variable names

Managed wrappers or generated scaffolding may reference only these names and path values:

- `AI_HARNESS_MCP_ENV_FILE`
- `AI_HARNESS_API_ENV_FILE`

Provider-specific credentials belong inside the external files or another local secret store. Do not place credential literals in Home Manager, `pi-harness`, generated MCP scaffolding, support notes, tests, or Git-tracked Nix values.

## Validation contract

Readiness checks must inspect only managed source files and Nix-generated activation text. They may verify that the external paths are named and that missing files produce a clear message, but they must not open or print local credential files.
