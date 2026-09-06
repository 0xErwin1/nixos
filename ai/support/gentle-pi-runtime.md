# Gentle Pi runtime repair

Home Manager keeps normal Pi provisioning skipped for Gentle AI installation, then reruns only the installed `gentle-pi` package lifecycle in a private FHS environment after provisioning.

## Why the skip remains

A fresh `gentle-pi` postinstall requires `/usr/bin/tar` or `/bin/tar`; NixOS does not expose either host path. The normal provisioner therefore retains `GENTLE_PI_SKIP_GENTLE_AI_INSTALL=1`. The repair wrapper sets it to `0` only for `npm rebuild --offline --ignore-scripts=false --prefix ~/.pi/agent/npm gentle-pi`, where its FHS provides `/usr/bin/tar` without changing global `PATH`.

## Ownership and review

The harness renderer is the pinned `0xErwin1/gentle-ai-nix` fork on its declarative branch. The package lifecycle remains `gentle-pi`'s original installer: it owns signed integrity validation, download repair, and atomic publication of its package-pinned Gentle AI review binary. This deliberately leaves the fork-rendered harness binary and the package-pinned review binary separate.

Activation is still the verification gate. Do not claim the native review runtime is repaired until an activation succeeds and the native facade accepts the resulting bundle.
