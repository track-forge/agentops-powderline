#!/usr/bin/env bash
# .powderline.init.sh — worktree bootstrap for Powderline agents
# Copy this to your repo root, customize, and make executable.
set -euo pipefail

# --- Credentials ---
# Symlink dev credentials if available on the host.
if [[ -f ~/.openclaw/credentials/env.local ]]; then
  ln -sf ~/.openclaw/credentials/env.local .env.local
  echo "Linked .env.local"
fi

# --- Dependencies ---
# Detect package manager and install.
if [[ -f pnpm-lock.yaml ]]; then
  pnpm install --frozen-lockfile
elif [[ -f package-lock.json ]]; then
  npm ci
elif [[ -f yarn.lock ]]; then
  yarn install --frozen-lockfile
fi

# --- Toolchain smoke check ---
# Verify critical tools are available after install.
# Uncomment and adjust for your project:
# npx tsc --version >/dev/null 2>&1 || { echo "TypeScript not available"; exit 1; }
# npx vitest --version >/dev/null 2>&1 || { echo "Vitest not available"; exit 1; }

echo "Worktree ready."
