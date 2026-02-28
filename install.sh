#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILLS_SRC="$SCRIPT_DIR/skills"

SKILLS=(
    planning-meeting
    execute-plan-task
)

# Target directories
CLAUDE_SKILLS="$HOME/.claude/skills"
AGENTS_SKILLS="$HOME/.agents/skills"
mkdir -p "$CLAUDE_SKILLS" "$AGENTS_SKILLS"

# Validate skills before installing
errors=0
for skill in "${SKILLS[@]}"; do
    skill_dir="$SKILLS_SRC/$skill"
    if [ ! -d "$skill_dir" ]; then
        echo "ERROR: Skill directory not found: $skill_dir"
        errors=$((errors + 1))
        continue
    fi
    if [ ! -f "$skill_dir/SKILL.md" ]; then
        echo "ERROR: SKILL.md not found in $skill_dir"
        errors=$((errors + 1))
        continue
    fi
    # Verify frontmatter has name field
    if ! head -5 "$skill_dir/SKILL.md" | grep -q "^name:"; then
        echo "ERROR: SKILL.md in $skill missing 'name:' frontmatter"
        errors=$((errors + 1))
    fi
done

if [ "$errors" -gt 0 ]; then
    echo ""
    echo "Validation failed with $errors error(s). Aborting install."
    exit 1
fi

# Install each skill
for skill in "${SKILLS[@]}"; do
    skill_dir="$SKILLS_SRC/$skill"

    # Claude Code
    if [ -L "$CLAUDE_SKILLS/$skill" ]; then
        rm "$CLAUDE_SKILLS/$skill"
    fi
    ln -s "$skill_dir" "$CLAUDE_SKILLS/$skill"
    echo "Installed to Claude Code: $CLAUDE_SKILLS/$skill -> $skill_dir"

    # Codex
    if [ -L "$AGENTS_SKILLS/$skill" ]; then
        rm "$AGENTS_SKILLS/$skill"
    fi
    ln -s "$skill_dir" "$AGENTS_SKILLS/$skill"
    echo "Installed to Codex: $AGENTS_SKILLS/$skill -> $skill_dir"
done

echo ""
echo "Done! ${#SKILLS[@]} skills installed:"
for skill in "${SKILLS[@]}"; do
    echo "  Claude Code: /$skill"
    echo "  Codex:       \$$skill"
done
