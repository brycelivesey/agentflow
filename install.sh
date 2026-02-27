#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILL_DIR="$SCRIPT_DIR/skills/planning-meeting"

# Claude Code: ~/.claude/skills/
CLAUDE_SKILLS="$HOME/.claude/skills"
mkdir -p "$CLAUDE_SKILLS"

if [ -L "$CLAUDE_SKILLS/planning-meeting" ]; then
    rm "$CLAUDE_SKILLS/planning-meeting"
fi
ln -s "$SKILL_DIR" "$CLAUDE_SKILLS/planning-meeting"
echo "Installed to Claude Code: $CLAUDE_SKILLS/planning-meeting -> $SKILL_DIR"

# Codex: ~/.agents/skills/
AGENTS_SKILLS="$HOME/.agents/skills"
mkdir -p "$AGENTS_SKILLS"

if [ -L "$AGENTS_SKILLS/planning-meeting" ]; then
    rm "$AGENTS_SKILLS/planning-meeting"
fi
ln -s "$SKILL_DIR" "$AGENTS_SKILLS/planning-meeting"
echo "Installed to Codex: $AGENTS_SKILLS/planning-meeting -> $SKILL_DIR"

echo ""
echo "Done! The planning-meeting skill is now available:"
echo "  Claude Code: /planning-meeting"
echo "  Codex:       \$planning-meeting"
