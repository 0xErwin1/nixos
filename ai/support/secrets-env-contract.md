# AI Harness Secrets Env-File Contract

Home Manager may reference secret locations, but it must not own secret values.

## External files

Create these files outside Git before the cutover switch:

- `/home/iperez/.config/ai-harness/secrets/mcp.env`
- `/home/iperez/.config/ai-harness/secrets/api.env`

The files are machine-local and should be mode `600`. They are not read by validation in this change.

## Managed variable names

Managed wrappers or generated scaffolding may reference only these names and path values:

- `AI_HARNESS_MCP_ENV_FILE`
- `AI_HARNESS_API_ENV_FILE`

Provider-specific credentials belong inside the external files or another local secret store. Do not place credential literals in Home Manager, `pi-harness`, generated MCP scaffolding, support notes, tests, or Git-tracked Nix values.

## Validation contract

Readiness checks must inspect only managed source files and Nix-generated activation text. They may verify that the external paths are named and that missing files produce a clear message, but they must not open or print local credential files.
