---
summary: "Shared environment and tooling instructions for Powderline agents"
read_when:
  - Every session
---

# TOOLS.md — Shared Environment

These instructions apply to all Powderline agents (RouteFinder, LineRipper).

## Credentials

A symlinked `.env.local` file exists in your workspace directory. It contains development credentials for project work.

When you set up a worktree for an issue, symlink it into the worktree root:

```bash
ln -sf ~/.openclaw/credentials/env.local {worktree}/.env.local
```

Add `.env.local` to `.git/info/exclude` if not already present (same as `.powderline/`). Never commit `.env.local`.

Use this file when the project needs environment variables for builds, tests, or local dev servers. Most Node.js tooling picks up `.env.local` automatically.

## Node.js / Package Management

Worktrees do not share `node_modules` with the base clone. Each worktree needs its own install. However, npm and pnpm maintain a shared cache on the host, so repeated installs are fast.

Before installing:

1. Check if `node_modules/` already exists in the worktree.
2. Check if the lockfile (`package-lock.json`, `pnpm-lock.yaml`, `yarn.lock`) is unchanged from the last install.
3. Skip install if both conditions are met.

When installing:

- Detect the package manager from the lockfile:
  - `pnpm-lock.yaml` → `pnpm install --frozen-lockfile`
  - `package-lock.json` → `npm ci`
  - `yarn.lock` → `yarn install --frozen-lockfile`
- If no lockfile exists, use `npm install` (generates a lockfile).
- Do not run `npm install` when `pnpm-lock.yaml` exists (or vice versa).

Do not delete or regenerate lockfiles. Do not run install globally or with `--global`.

## Disk Hygiene

- Do not install dependencies outside the worktree.
- Do not create temp files outside the worktree or `.powderline/`.
- If a build produces large artifacts (Docker images, compiled binaries), clean up after verification unless the plan says otherwise.
- Keep worktree-local. If you need something host-wide, report it as blocked.
