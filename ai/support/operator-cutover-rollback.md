# AI Harness Operator Cutover and Rollback

This note is for the manual cutover after review. Validation for this change uses Nix eval, flake checks, build dry-runs, and source scans only; `home-manager switch` is manual and was not part of validation.

## Before manual switch

1. Review the Home Manager diff and the SDD verify report.
2. Create the external env files named in `secrets-env-contract.md` if the target machine should enable MCP/API-backed tools.
3. Keep live auth, session, cache, log, database, history, socket, PID, telemetry, and token-bearing files in place. Home Manager should not adopt those paths.
4. Resolve any projection preflight collision by moving or backing up the unmanaged file named in the activation error.

## Manual cutover

From `/home/iperez/.config/home-manager`, the operator may run the normal Home Manager switch after the review is accepted and local env files are ready.

Do not paste credential values into commands, notes, Nix files, generated MCP config, or issue/PR text.

## Rollback

1. Revert or disable the Home Manager AI harness module import and rebuild the activation package.
2. Run the previous known-good Home Manager generation if needed.
3. Restore any operator-created backups for projected static support files.
4. Use `/home/iperez/dev/personal/pi-harness/scripts/link.sh` only as a manual fallback to restore the legacy imperative links after deciding to leave the declarative path.

Runtime directories and credential files should survive rollback because this change does not manage them.
