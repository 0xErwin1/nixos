# AI Harness Projection Preflight

Home Manager projections must not silently replace unmanaged files or symlinks in live tool directories.

The managed projection set includes real AI harness assets such as:

- `.pi/agent/AGENTS.md`
- `.pi/agent/skills`
- `.agents/skills`
- `.config/opencode/{AGENTS.md,ORCHESTRATOR.md,agent,command,commands,skills,opencode.jsonc,tui.json}`
- `.claude/{CLAUDE.md,sdd-orchestrator.md,engram-protocol.md,agents,commands,skills}`
- `.codex/{AGENTS.md,sdd-orchestrator.md,engram-instructions.md,engram-compact-prompt.md,skills}`
- `.grok/{AGENTS.md,ORCHESTRATOR.md,agents}` (MCP section merged into `.grok/config.toml`)

The preflight guards **single-file targets** only. Home Manager materializes each single-file projection as a whole-path `/nix/store/` symlink, so if such a target already exists as an unmanaged regular file or unmanaged symlink, activation stops and asks the operator to resolve the collision before retrying. Existing symlinks into `/nix/store/` are treated as already Home Manager/Nix-managed and may be replaced by the new generation.

**Recursive directory targets** (`.agents/skills`, `.config/opencode/{agent,command,commands,skills}`, `.claude/{agents,commands,skills}`, `.codex/skills`, `.grok/agents`, etc.) are materialized as a real directory whose leaf files are the managed symlinks — the directory itself is never a symlink. The preflight therefore skips them; checking the directory's top level would abort on every switch after the first. Genuine leaf-file collisions inside these directories are still caught by Home Manager's own file-collision detection.
