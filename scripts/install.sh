#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"

FORCE=false
OPENCLAW_HOME="${1:-$HOME/.openclaw}"

for arg in "$@"; do
  case "$arg" in
    --force) FORCE=true ;;
    --help|-h)
      echo "Usage: install.sh [OPENCLAW_HOME] [--force]"
      echo ""
      echo "  OPENCLAW_HOME  Path to OpenClaw home directory (default: ~/.openclaw)"
      echo "  --force        Overwrite existing files without prompting"
      exit 0
      ;;
  esac
done

if [[ "$1" == "--force" ]]; then
  OPENCLAW_HOME="$HOME/.openclaw"
fi

SKILL_DIR="$OPENCLAW_HOME/workspace/skills/agentops-powderline"
RF_WORKSPACE="$OPENCLAW_HOME/agents/routefinder/workspace"
LR_WORKSPACE="$OPENCLAW_HOME/agents/lineripper/workspace"
CREDENTIALS_DIR="$OPENCLAW_HOME/credentials"
ENV_LOCAL="$CREDENTIALS_DIR/env.local"

copy_file() {
  local src="$1"
  local dst="$2"

  if [[ -f "$dst" ]] && [[ "$FORCE" != "true" ]]; then
    echo "SKIP (exists): $dst"
    echo "  Use --force to overwrite."
    return 1
  fi

  mkdir -p "$(dirname "$dst")"
  cp "$src" "$dst"
  echo "  -> $dst"
}

echo "Installing agentops-powderline to: $OPENCLAW_HOME"
echo ""

skipped=0

echo "=== Skill files ==="
copy_file "$REPO_ROOT/SKILL.md" "$SKILL_DIR/SKILL.md" || skipped=$((skipped + 1))

echo ""
echo "=== Assets ==="
for f in "$REPO_ROOT"/assets/*.md; do
  copy_file "$f" "$SKILL_DIR/assets/$(basename "$f")" || skipped=$((skipped + 1))
done

echo ""
echo "=== References ==="
for f in "$REPO_ROOT"/references/*.md; do
  copy_file "$f" "$SKILL_DIR/references/$(basename "$f")" || skipped=$((skipped + 1))
done

echo ""
echo "=== Shared TOOLS.md ==="
copy_file "$REPO_ROOT/assets/TOOLS.md" "$RF_WORKSPACE/TOOLS.md" || skipped=$((skipped + 1))
copy_file "$REPO_ROOT/assets/TOOLS.md" "$LR_WORKSPACE/TOOLS.md" || skipped=$((skipped + 1))

echo ""
echo "=== RouteFinder agent workspace ==="
for f in "$REPO_ROOT"/agents/routefinder/*.md; do
  copy_file "$f" "$RF_WORKSPACE/$(basename "$f")" || skipped=$((skipped + 1))
done

echo ""
echo "=== LineRipper agent workspace ==="
for f in "$REPO_ROOT"/agents/lineripper/*.md; do
  copy_file "$f" "$LR_WORKSPACE/$(basename "$f")" || skipped=$((skipped + 1))
done

echo ""
echo "=== Credentials symlink ==="
if [[ -f "$ENV_LOCAL" ]]; then
  for ws in "$RF_WORKSPACE" "$LR_WORKSPACE"; do
    mkdir -p "$ws"
    if [[ -L "$ws/.env.local" ]]; then
      echo "  OK (symlink exists): $ws/.env.local"
    else
      ln -sf "$ENV_LOCAL" "$ws/.env.local"
      echo "  -> $ws/.env.local -> $ENV_LOCAL"
    fi
  done
else
  echo "  SKIP: $ENV_LOCAL not found."
  echo "  Create it and re-run install, or symlink manually:"
  echo "    ln -sf $ENV_LOCAL $RF_WORKSPACE/.env.local"
  echo "    ln -sf $ENV_LOCAL $LR_WORKSPACE/.env.local"
fi

echo ""
if [[ $skipped -gt 0 ]]; then
  echo "$skipped file(s) skipped (already exist). Use --force to overwrite."
  echo ""
fi

echo "=== Done ==="
echo ""
echo "Next steps:"
echo ""
echo "1. Add these entries to agents.list[] in $OPENCLAW_HOME/openclaw.json:"
echo ""
cat <<'AGENTS_JSON'
    {
      "id": "routefinder",
      "name": "RouteFinder",
      "model": "openai-codex/gpt-5.5",
      "workspace": "~/.openclaw/agents/routefinder/workspace",
      "skills": [],
      "tools": { "deny": ["sessions_spawn"] }
    },
    {
      "id": "lineripper",
      "name": "LineRipper",
      "model": "openai-codex/gpt-5.3-codex",
      "workspace": "~/.openclaw/agents/lineripper/workspace",
      "skills": [],
      "tools": { "deny": ["sessions_spawn"] }
    }
AGENTS_JSON
echo ""
echo "2. Ensure your coordinator agent can spawn subagents."
echo "   If agents.defaults.subagents.maxSpawnDepth is not set, it defaults to 1."
echo "   That's sufficient — RouteFinder and LineRipper are leaf agents."
echo ""
echo "3. Ensure your coordinator agent's subagents.allowAgents includes"
echo "   'routefinder' and 'lineripper' (or use '*' for all)."
echo ""
echo "4. Restart the gateway: openclaw gateway restart"
