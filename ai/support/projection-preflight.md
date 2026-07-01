# AI Harness Projection Preflight

Home Manager projections must not silently replace unmanaged files in live tool directories.

For this initial proof, only new non-secret support targets are selected:

- `.pi/agent/support/home-manager-canonical-assets.md`
- `.config/opencode/support/home-manager-canonical-assets.md`

If either target already exists as an unmanaged regular file or unmanaged symlink, activation should stop and ask the operator to resolve the collision before retrying. Existing symlinks into `/nix/store/` are treated as already Home Manager/Nix-managed and may be replaced by the new generation.
