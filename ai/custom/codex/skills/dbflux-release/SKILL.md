---
name: dbflux-release
description: >
  Create versioned releases for DBFlux with automated version bumping across all package manifests.
  Trigger: When user asks to create a release, bump version, tag a release, or prepare a new version.
license: Apache-2.0
metadata:
  version: "1.0"
---

## When to Use

- User requests a release or version bump
- User asks to tag a new version
- User mentions updating CHANGELOG or version numbers
- Preparing a stable or dev release

## Versioning Rules

### main branch (stable)
- Format: `vX.Y.Z`
- **X** (major): Breaking changes or significant milestones
  - While X=0: Y acts as major version
- **Y** (minor): Important features or changes
- **Z** (patch): Bug fixes and small improvements

### dev branch (unstable)
- Format: `vX.Y.Z-dev.W`
- X.Y.Z: Next planned version from main
- **W**: Dev iteration counter (increments with each dev release)
- X.Y.Z remain stable until merged to main

## Release Workflow

### 1. Version Decision
**User priority**: Always prefer user-specified version over automated suggestions.

If user doesn't specify:
- Check current branch (main vs dev)
- Get last tag: `git describe --tags --abbrev=0`
- Compare changes: `git log <last-tag>..HEAD --oneline`
- Analyze changes for breaking/feature/fix patterns
- Suggest appropriate version bump

### 2. Pre-Release Validation
Run quality checks **before** committing version bump:

```bash
cargo build
cargo check --workspace
cargo clippy --workspace -- -D warnings
cargo fmt --all -- --check
cargo test --workspace
```

**All checks must pass**. If any fail, abort the release and report errors.

### 3. Version Bump Files

Update version in ALL these files:

| File | Format | Notes |
|------|--------|-------|
| `Cargo.toml` (workspace) | `version = "X.Y.Z"` | Root workspace version |
| `crates/*/Cargo.toml` | `version = "X.Y.Z"` | All crate versions |
| `flake.nix` | `version = "X.Y.Z";` | Nix package version |
| `resources/windows/installer.iss` | `Version="X.Y.Z"` | Windows installer |
| `scripts/PKGBUILD` | `pkgver=X.Y.Z` | Arch Linux package |
| `CHANGELOG.md` | Add section `## [X.Y.Z] - YYYY-MM-DD` | Release notes |

**Strip version prefix**: Files use `X.Y.Z` not `vX.Y.Z` (tag has the `v` prefix).

### 4. CHANGELOG Update

Compare commits since last tag:

```bash
git log <last-tag>..HEAD --pretty=format:"- %s" --reverse
```

Group changes by category:
- **Breaking Changes**: API changes, removed features
- **Features**: New functionality
- **Fixes**: Bug fixes
- **Improvements**: Performance, UX enhancements
- **Chores**: Dependencies, refactoring

Add new section at top of CHANGELOG.md:

```markdown
## [X.Y.Z] - YYYY-MM-DD

### Breaking Changes
- ...

### Features
- ...

### Fixes
- ...
```

### 5. Commit and Tag

```bash
# Stage all version changes
git add Cargo.toml crates/*/Cargo.toml flake.nix packaging/ CHANGELOG.md

# Commit with version bump message
git commit -m "chore: bump version to vX.Y.Z"

# Create annotated tag
git tag -a vX.Y.Z -m "Release vX.Y.Z"
```

## Commands

```bash
# Check last tag
git describe --tags --abbrev=0

# Compare with last tag
git log $(git describe --tags --abbrev=0)..HEAD --oneline

# Pre-release checks
cargo build && \
cargo check --workspace && \
cargo clippy --workspace -- -D warnings && \
cargo fmt --all -- --check && \
cargo test --workspace

# Update all workspace crate versions
find crates -name Cargo.toml -exec sed -i 's/^version = ".*"/version = "X.Y.Z"/' {} \;

# Stage version files
git add Cargo.toml crates/*/Cargo.toml flake.nix packaging/ CHANGELOG.md

# Create release
git commit -m "chore: bump version to vX.Y.Z"
git tag -a vX.Y.Z -m "vX.Y.Z"
```

## Decision Trees

### Branch Detection
```
Current branch = main?
├─ Yes → Stable release (vX.Y.Z)
└─ No  → Check if dev branch
          ├─ Yes → Dev release (vX.Y.Z-dev.W)
          └─ No  → Warn: releases only from main/dev
```

### Version Increment (main)
```
Breaking changes found?
├─ Yes → Bump major (or minor if X=0)
└─ No  → New features found?
          ├─ Yes → Bump minor
          └─ No  → Bump patch
```

### Version Increment (dev)
```
Last tag format = vX.Y.Z-dev.W?
├─ Yes → Increment W
└─ No  → Create vX.Y.Z-dev.1 (X.Y.Z = next main version)
```

## Critical Patterns

### 1. Version String Handling
```rust
// In files: NO 'v' prefix
version = "0.2.1"

// In git tags: YES 'v' prefix
git tag -a v0.2.1
```

### 2. Workspace Version Sync
All crates must have identical versions. Use workspace-level version or explicit sync.

```toml
# Root Cargo.toml
[workspace.package]
version = "0.2.1"

# Crate Cargo.toml
[package]
version.workspace = true
```

If not using workspace inheritance, update each `crates/*/Cargo.toml` individually.

### 3. Pre-Release Validation is Non-Negotiable
Never commit version bumps if checks fail. GitHub Actions will fail anyway.

### 4. User Version Priority
```
User specifies version → Use it (validate format only)
User says "decide" → Analyze commits and suggest
User silent → Ask for version or permission to decide
```

### 5. CHANGELOG Commit Analysis
Parse commit messages for conventional commit patterns:

- `feat:` or `feat(...)` → Features
- `fix:` or `fix(...)` → Fixes
- `BREAKING CHANGE:` or `!` → Breaking Changes
- `chore:`, `refactor:`, `perf:` → Improvements/Chores

### 6. Atomic Release
All steps must succeed or abort:
1. ✅ Pre-release checks pass
2. ✅ All files updated
3. ✅ CHANGELOG updated
4. ✅ Commit created
5. ✅ Tag created
6. Pushed to remote by User

If any step fails, rollback changes and report error.

## Example Flow

```
User: "Create a new release"
