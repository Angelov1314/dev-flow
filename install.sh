#!/usr/bin/env bash
set -euo pipefail

# Dev Flow — Claude Code Skill Installer
# Copies skills to ~/.claude/skills/ for auto-discovery

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SKILLS_DIR="$HOME/.claude/skills"

echo "Dev Flow Installer"
echo "=================="
echo ""

# Check Claude Code is available
if ! command -v claude &> /dev/null; then
  echo "Warning: 'claude' CLI not found in PATH."
  echo "Skills will be installed but may not be discovered until Claude Code is available."
  echo ""
fi

# Skills to install
SKILLS=(
  "dev-flow"
  "project-scoper"
  "repo-bootstrap"
  "ralph"
  "architect"
  "planner"
  "santa-method"
  "dev-router"
)

INSTALLED=0
SKIPPED=0

for skill in "${SKILLS[@]}"; do
  SRC="$SCRIPT_DIR/skills/$skill"
  DEST="$SKILLS_DIR/$skill"

  if [ ! -d "$SRC" ]; then
    echo "  SKIP: $skill (source not found)"
    ((SKIPPED++))
    continue
  fi

  if [ -d "$DEST" ]; then
    # Check if existing skill is different
    if diff -rq "$SRC" "$DEST" &> /dev/null 2>&1; then
      echo "  OK:   $skill (already up to date)"
      ((SKIPPED++))
      continue
    else
      echo "  UPDATE: $skill (overwriting existing)"
    fi
  else
    echo "  INSTALL: $skill"
  fi

  mkdir -p "$DEST"
  cp -r "$SRC"/* "$DEST"/
  ((INSTALLED++))
done

echo ""
echo "Done: $INSTALLED installed/updated, $SKIPPED unchanged"
echo ""
echo "Skills are now available in Claude Code:"
echo "  /dev-flow          — full end-to-end pipeline"
echo "  /project-scoper    — scope a project"
echo "  /repo-bootstrap    — set up repo for autonomous dev"
echo "  /ralph             — gated autonomous loop"
echo "  /architect         — architecture design"
echo "  /planner           — implementation planning"
echo "  /santa-method      — adversarial review"
echo "  /dev-router        — register project in local launcher"
echo ""
echo "Quick start:"
echo '  /dev-flow "Build a SaaS todo app with auth and billing"'
