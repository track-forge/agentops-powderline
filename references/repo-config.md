# Per-Repo Powderline Configuration

Target repos can include two optional files at their root to customize Powderline behavior.

## POWDERLINE.md

Human-readable instructions that agents read at startup. This file tells agents how the repo works — what tools are available, how to validate changes, project-specific constraints, and gotchas.

### Suggested sections

```markdown
# Powderline — {repo name}

## Toolchain
- Node version, package manager, required CLIs

## Setup Notes
- Anything agents should know about the dev environment
- Credential files, environment variables, config

## Validation Ladder
1. Cheap checks (syntax, lint)
2. Typecheck
3. Focused tests (by area)
4. Full local gate (build + all tests)

## Project Constraints
- Directories to avoid
- Files that need special handling
- Architecture rules

## Known Gotchas
- CI quirks, flaky tests, platform-specific issues
```

All sections are optional. Repos without a `POWDERLINE.md` work fine — agents fall back to repo-level `AGENTS.md` / `CLAUDE.md` and their own heuristics.

## .powderline.init.sh

Executable bootstrap script that the coordinator runs in the worktree **before** spawning any agents. Its job is to make the worktree ready for development — install dependencies, symlink credentials, verify the toolchain.

### Contract

- Must be executable (`chmod +x`).
- Runs with the worktree as the working directory.
- Must exit 0 on success, non-zero on failure.
- Should be idempotent — safe to run multiple times.
- Should complete in a reasonable time (under 5 minutes).
- Should not modify files outside the worktree.
- Should not commit, push, or interact with GitHub.

### Example

```bash
#!/usr/bin/env bash
set -euo pipefail

# Symlink credentials
ln -sf ~/.openclaw/credentials/env.local .env.local

# Install dependencies
npm ci

# Smoke check toolchain
npx tsc --version >/dev/null 2>&1 || { echo "TypeScript not available"; exit 1; }

echo "Worktree ready."
```

### What belongs in .powderline.init.sh vs POWDERLINE.md

| Concern | .powderline.init.sh | POWDERLINE.md |
|---------|-------------------|---------------|
| Install deps | Yes | No |
| Symlink credentials | Yes | No |
| Verify toolchain | Yes | No |
| Validation commands | No | Yes |
| Project constraints | No | Yes |
| Architecture rules | No | Yes |
| Test commands | No | Yes |

The init script does automated setup. POWDERLINE.md provides context and instructions that agents interpret during their work.

## Discovery

The coordinator checks for both files in the worktree root after creating/reusing the worktree (Phase 3). Agents check for `POWDERLINE.md` during their startup sequence.

Neither file is required. Both are gitignored-safe — they can be committed to the target repo since they contain no secrets (credentials are symlinked from the host, not embedded).
