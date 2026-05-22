#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"

REQUIRED_FILES=(
  "SKILL.md"
  "agents/routefinder/AGENTS.md"
  "agents/routefinder/SOUL.md"
  "agents/routefinder/IDENTITY.md"
  "agents/lineripper/AGENTS.md"
  "agents/lineripper/SOUL.md"
  "agents/lineripper/IDENTITY.md"
  "assets/TOOLS.md"
  "assets/mission-template.md"
  "assets/plan-template.md"
  "assets/pr-body-template.md"
  "references/labels.md"
  "references/milestone-rules.md"
  "references/workspace-layout.md"
)

missing=0

for f in "${REQUIRED_FILES[@]}"; do
  if [[ ! -f "$REPO_ROOT/$f" ]]; then
    echo "MISSING: $f"
    missing=$((missing + 1))
  fi
done

if [[ $missing -gt 0 ]]; then
  echo ""
  echo "$missing required file(s) missing."
  exit 1
fi

echo "All ${#REQUIRED_FILES[@]} required files present."
