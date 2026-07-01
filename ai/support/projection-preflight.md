# AI Harness Projection Preflight

Home Manager projections must not silently replace unmanaged files or symlinks in live tool directories.

The managed projection set includes real AI harness assets such as:

- `.pi/agent/AGENTS.md`
- `.pi/agent/skills`
- `.agents/skills`
- `.config/opencode/{AGENTS.md,ORCHESTRATOR.md,agent,command,commands,skills,opencode.jsonc,tui.json}`
- `.claude/{CLAUDE.md,sdd-orchestrator.md,engram-protocol.md,agents,commands,skills}`
- `.codex/{AGENTS.md,sdd-orchestrator.md,engram-instructions.md,skills}`

If any selected target already exists as an unmanaged regular file or unmanaged symlink, activation should stop and ask the operator to resolve the collision before retrying. Existing symlinks into `/nix/store/` are treated as already Home Manager/Nix-managed and may be replaced by the new generation.
