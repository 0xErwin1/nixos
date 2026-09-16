# gentle-pi-runtime-repair-path

The home-manager config points the gentle-pi runtime repair at the git checkout
that stopped existing when the repository was renamed.

- Found by: the native review preflight in this session
  (`gentle_review inspect` → `review/status: package-local-binary-missing`), then
  traced to `--package-dir .../Gentleman-Programming/gentle-pi`.
- Status: done (2026-09-16). The repository's own check went from red to green.
  Nothing committed in this repository either; the pre-existing uncommitted work
  in `ai-harness-gentle-ai.nix` (the `onNan` helpers) is untouched by this change.

## What is broken

`home.activation.gentlePiRuntimeRepair` repairs two homes for gentle-pi's
postinstall: the npm prefix (the stable channel) and the git checkout (main).
The checkout is named after the repository Pi clones, which is now
`gentle-shell`; the literal still said `gentle-pi`. The repair prints
`no package at <dir>; nothing to repair` and exits 0, so the miss is silent and
`<checkout>/.gentle-ai/<version>/gentle-ai` is never extracted. That missing
bundled binary is what the native review preflight needs, so the review of the
change in `gentle-ai-nix` cannot start.

## Two more things found while tracing it

- `tests/gentle-pi-runtime-repair.nix` pins the `--prefix` spelling of the
  activation but not the `--package-dir` one, which is why a rename could slip
  through a check that exists to catch exactly this.
- `tests/gentle-pi-runtime-repair.sh` still expects the repair to *fail* on a
  package that is not installed. Commit 2bc0695 made that a deliberate no-op
  ("no longer fails when a prefix holds no gentle-pi at all"), because activation
  runs both homes on every switch and only one of them is ever in use. The
  expectation was never updated, so this check is red on the current tree.

## Tasks

- [x] `home-manager/global/ai-harness-gentle-ai.nix`: point `--package-dir` at
      `gentle-shell`, and say why the checkout name differs from the package
      identity.
- [x] `tests/gentle-pi-runtime-repair.nix`: pin the `--package-dir` spelling too,
      so an edit to it is a failure rather than a silent no-op.
- [x] `tests/gentle-pi-runtime-repair.sh`: assert the missing-package tolerance
      for both homes, and exercise the `--package-dir` branch (a checkout
      fixture, its postinstall, and its failing-postinstall propagation).
- [x] Verify with the repository's own check.
- [x] Run the repair against the real checkout and re-run the native review
      preflight over the `gentle-ai-nix` candidate.

## Known follow-up, not in this change

The directory is derived from the install source `gentle-ai-nix` owns
(`git:github.com/Gentleman-Programming/gentle-shell@<rev>`), so this config
restates a fact another flake decides. Exposing the resolved Pi package
directory from `gentle-ai-nix` would remove the coupling; it is a separate,
reviewable change.

## Evidence

- Before the change, `nix build .#checks.x86_64-linux.gentle-pi-runtime-repair`
  failed: the fixture's `FAIL_POSTINSTALL=1` run was accepted as a failure of the
  *missing prefix* assertion (`repair accepted a missing gentle-pi package`),
  because the test still expected the fail-on-missing behaviour that 2bc0695
  deliberately replaced.
- After the change, the same command with `--rebuild` builds
  `/nix/store/7hl3rs5x0i9yjgpblf837305gdg98w0c-gentle-pi-runtime-repair` and exits
  0.
- The new assertion was proved to bite, without editing the repository: importing
  `tests/gentle-pi-runtime-repair.nix` with stub home configurations whose
  activation names the old `gentle-pi` path throws
  (`stalePathAccepted: false`), while the `gentle-shell` path evaluates
  (`renamedPathAccepted: true`).
- `shellcheck tests/gentle-pi-runtime-repair.sh` passes. The `.nix` files were
  left in the repository's own hand style: `nixfmt-rfc-style --check` also
  rejects the file as it stood at HEAD, so the rfc-style formatter is not this
  repository's convention.
- The real repair now runs against the installed checkout:
  `gentle-pi-runtime-repair --package-dir ~/.pi/agent/git/github.com/Gentleman-Programming/gentle-shell`
  reported `Gentle AI v2.9.1 installed at
  <checkout>/.gentle-ai/v2.9.1/gentle-ai`.
- With that binary present, `gentle_review inspect` in `gentle-ai-nix` no longer
  fails: lineage `review-41831c6d85453fba` started, was approved, and its
  acknowledgement burned the authority.
