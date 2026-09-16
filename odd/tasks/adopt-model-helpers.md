# adopt-model-helpers

Move this configuration's Pi model assignments onto the helpers gentle-ai-nix now
exports, instead of the local `let` that rebuilt them by hand.

- Requested by: Ignacio (2026-09-16), after the helpers shipped in
  gentle-ai-nix.
- Status: done (2026-09-16). Built and compared; **not** switched, by request.

## What changes

- `flake.lock`: the `gentle-ai-nix` input moves to the commit that carries
  `lib.models` and `providers.<id>.profiles.<name>.defaultEffort`.
- `home-manager/global/ai-harness-gentle-ai.nix`: the profiles block loses its
  hand-written `onCodex`/`onNan` constructors and takes them from
  `inputs.gentle-ai-nix.lib.models.for`; each model keeps a binding, the effort
  becomes a prefix (`models.effort.low astra`), and the `nan` profile states its
  one level once as `defaultEffort` instead of on all 26 lines.

## Non-goal

The routing must not change. This is a refactor of how the same assignments are
written, so the equivalence check is the deliverable: the rendered tree's
`.pi/gentle-ai/profiles.json` and `models.json` have to match, byte for byte, the
files the previous activation wrote (kept at `/tmp/pi-gentle-ai-before/`).

## Tasks

- [x] `nix flake update gentle-ai-nix` to the helpers commit (`9e4aae4`).
- [x] Rewrite the profiles block: `models.for`, effort prefixes, `defaultEffort`.
- [x] Build the rendered tree and diff the routing files against the baseline.
- [x] Commit and push. No `home-manager switch`.

## Evidence

- `nix flake update gentle-ai-nix` moved the input from `9203a4a` to
  `9e4aae494a23a162f224bd820a28c0c1c680ca79`.
- Equivalence, against `/tmp/pi-gentle-ai-before/` (copied from
  `~/.pi/gentle-ai/` while generation 635 was active):
  - `diff` of `.pi/gentle-ai/profiles.json` between the baseline and
    `/nix/store/73z70ingmlrbjwjkn1cjgrs6vy3nhj0g-.../tree/`: identical. That file
    holds every declared profile, so the check covers `codex`, `nan` and
    `performance` at once.
  - `diff` of `.pi/gentle-ai/models.json`: identical.
  - `defaultProvider`, `defaultModel`, `defaultThinkingLevel`:
    `openai-codex` / `gpt-6-astra` / `high` on both sides.
- The nan profile went from 26 assignments each repeating `"high"` to 26 without
  it plus one `defaultEffort`; `codex` and `performance` keep stating their level
  per assignment, as a prefix over the model binding, because neither has a
  single level to state once.
