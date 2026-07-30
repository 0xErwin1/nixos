# Home Manager Canonical AI Assets

The canonical copy of shared AI harness assets now lives under `/home/iperez/.config/home-manager/ai/`.

Home Manager projects selected files and directories from this tree into tool-specific locations for Pi, OpenCode, Claude, Codex, Grok Build, and shared agent skills. The previous external asset hub is no longer the intended canonical source for these managed assets.

Managed examples include skills, agents, commands, orchestrators, prompts, static support notes, non-secret tool configuration files selected by the Home Manager module, and `ai/shared/engram-protocol.md` as the canonical source for rendered Engram provider files.

Unmanaged examples include auth files, sessions, caches, logs, databases, histories, sockets, PIDs, telemetry, local backups, and machine-local secret files.

Agens' runtime-owned `~/.config/agens/config.toml` is merged additively: Home Manager appends a canonical MCP table or `[permissions]` table only when that exact table is absent. Existing MCPs (including canonical names), permissions, comments, and unrelated settings remain unchanged.
