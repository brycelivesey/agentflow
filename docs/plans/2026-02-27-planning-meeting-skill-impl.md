# Planning Meeting Skill - Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Create the agentflow planning-meeting skill that works with both Claude Code and Codex, producing structured plans for trunk-based development.

**Architecture:** A single SKILL.md file with YAML frontmatter (compatible with both tools), a plan output template, and an install script that symlinks to both `~/.claude/skills/` and `~/.agents/skills/`.

**Tech Stack:** Markdown (SKILL.md format), Bash (install script)

---

### Task 1: Create project directory structure

**Files:**
- Create: `skills/planning-meeting/` (directory)
- Create: `templates/` (directory)

**Step 1: Create directories**

Run:
```bash
cd /Users/brycelivesey/Projects/agentflow
mkdir -p skills/planning-meeting
mkdir -p templates
```

**Step 2: Verify structure**

Run: `ls -R /Users/brycelivesey/Projects/agentflow/`
Expected: `skills/planning-meeting/`, `templates/`, `docs/plans/` all exist

**Step 3: Commit**

```bash
git add -A
git commit -m "scaffold: create agentflow directory structure"
```

---

### Task 2: Write the planning-meeting SKILL.md

**Files:**
- Create: `skills/planning-meeting/SKILL.md`

**Step 1: Write the skill file**

Create `skills/planning-meeting/SKILL.md` with the following content:

```markdown
---
name: planning-meeting
description: Use when starting feature work, planning a new feature, or beginning a user story. This skill guides a collaborative planning conversation that produces small, stacked tasks for trunk-based development. Triggers on phrases like "plan a feature", "planning meeting", "let's plan", "new feature", "user story", "break this into tasks".
---

# Planning Meeting

## Overview

Conduct a collaborative planning meeting to break a feature into small, stacked tasks suitable for trunk-based development. Inspired by Facebook's engineering culture: small diffs, one idea per change, reviewable in ~15 minutes.

## Process

### Phase 1: Listen

The user describes the feature or user story they want to build. Listen and understand before doing anything else.

### Phase 2: Research

Before asking the user any questions, explore the codebase thoroughly:

- Read relevant source files, configs, and existing architecture
- Check for existing patterns, conventions, and prior implementations of similar features
- Look at recent commits and any existing plans in `.agentflow/plans/`
- Identify the components, modules, and files that will likely be affected
- Form your own understanding of constraints, dependencies, and risks

The goal is to answer as many of your own questions as possible from the code. Only ask the user things you genuinely cannot determine from the codebase.

### Phase 3: Clarify

Ask the user clarifying questions. Consider these perspectives, but let the context determine which questions matter:

- **Product:** Who is this for? What problem does it solve? What does success look like?
- **Architecture:** How does this fit with the existing system? What components are affected? What patterns should we follow or deviate from?
- **Engineering:** What's the complexity? What are the risky parts? What could go wrong? What are the performance implications?
- **Testing/QA:** How do we verify this works? What are the edge cases? What's the test strategy?

Ask questions naturally. There is no limit on the number of questions. Thoroughness matters more than speed. Research the codebase between questions if new information changes what you need to ask.

### Phase 4: Discuss Approach

Share your recommended technical approach and why you think it's best. Also present alternatives worth considering. This is a back-and-forth conversation:

- Explain trade-offs honestly
- Be open to the user's preferences and domain knowledge
- Go back and forth until you both agree on an approach
- Don't force a fixed number of options - present what's relevant

### Phase 5: Break Into Tasks

Decompose the agreed approach into stacked tasks following these principles:

- **One logical change per task** - each task is one idea, one diff
- **Reviewable in ~15 minutes** - a reviewer should be able to understand the full context quickly
- **Clear acceptance criteria** - how do we know the task is done?
- **Defined dependencies** - what must land before this task can start?
- **Layer-based when appropriate** - consider stacking: data model → API → UI → tests
- **No hard line count** - size by cohesion, not by counting lines

### Phase 6: Output Plan

Write the plan using the template below. Present it to the user for review. After approval, commit it to the target project at:

```
<project-root>/.agentflow/plans/YYYY-MM-DD-<feature-name>.md
```

Create the `.agentflow/plans/` directory if it doesn't exist.

## Plan Output Template

Use this structure for the final plan document:

```markdown
# [Feature Name]

## User Story
[What the user wants, in their words]

## Context
[What was learned from exploring the codebase - relevant files, existing patterns, constraints discovered]

## Discussion Summary
[Key points from the planning conversation - decisions made, questions raised and answered, concerns addressed]

## Approach
[The agreed technical approach and why it was chosen]

### Alternatives Considered
[Other approaches discussed and why they weren't chosen]

## Tasks

### Task 1: [Name]
- **Description:** What this task accomplishes
- **Acceptance Criteria:** How we know it's done
- **Dependencies:** What must land before this
- **Files likely affected:** [list]
- **Layer:** data / api / ui / test / infra

### Task 2: [Name]
...
(continue for all tasks)

## Open Questions
[Anything unresolved that might come up during implementation]
```

## Key Principles

- Research first, ask second. Explore the codebase before asking the user questions.
- No scripted questions. Let context determine what to ask.
- Natural conversation. This is a collaborative discussion, not a form to fill out.
- One idea per diff. Every task should be a single, coherent change.
- Trunk-based development. Small changes that land on main frequently.
```

**Step 2: Verify the file exists and is valid**

Run: `head -5 skills/planning-meeting/SKILL.md`
Expected: Shows the YAML frontmatter starting with `---`

**Step 3: Commit**

```bash
git add skills/planning-meeting/SKILL.md
git commit -m "feat: add planning-meeting skill

Collaborative planning workflow that produces small, stacked tasks
for trunk-based development. Compatible with both Claude Code and
Codex skill systems."
```

---

### Task 3: Write the plan output template as a standalone reference

**Files:**
- Create: `templates/plan-output.md`

**Step 1: Write the template file**

Create `templates/plan-output.md` with the plan template structure. This is a standalone copy of the template for reference and for tools that want to load it separately from the skill.

```markdown
# [Feature Name]

## User Story
[What the user wants, in their words]

## Context
[What was learned from exploring the codebase - relevant files, existing patterns, constraints discovered]

## Discussion Summary
[Key points from the planning conversation - decisions made, questions raised and answered, concerns addressed]

## Approach
[The agreed technical approach and why it was chosen]

### Alternatives Considered
[Other approaches discussed and why they weren't chosen]

## Tasks

### Task 1: [Name]
- **Description:** What this task accomplishes
- **Acceptance Criteria:** How we know it's done
- **Dependencies:** What must land before this
- **Files likely affected:** [list]
- **Layer:** data / api / ui / test / infra

### Task 2: [Name]
...

## Open Questions
[Anything unresolved that might come up during implementation]
```

**Step 2: Commit**

```bash
git add templates/plan-output.md
git commit -m "docs: add standalone plan output template"
```

---

### Task 4: Write the install script

**Files:**
- Create: `install.sh`

**Step 1: Write the install script**

Create `install.sh`:

```bash
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
```

**Step 2: Make it executable**

Run: `chmod +x install.sh`

**Step 3: Commit**

```bash
git add install.sh
git commit -m "feat: add install script for dual-tool skill symlinks"
```

---

### Task 5: Run the install script and verify

**Step 1: Run install**

Run: `cd /Users/brycelivesey/Projects/agentflow && ./install.sh`
Expected: Two success messages showing symlinks created

**Step 2: Verify symlinks**

Run: `ls -la ~/.claude/skills/planning-meeting && ls -la ~/.agents/skills/planning-meeting`
Expected: Both point to `/Users/brycelivesey/Projects/agentflow/skills/planning-meeting`

**Step 3: Verify skill content is accessible**

Run: `cat ~/.claude/skills/planning-meeting/SKILL.md | head -5`
Expected: Shows the YAML frontmatter

---

### Task 6: Final commit with all files

**Step 1: Check status**

Run: `cd /Users/brycelivesey/Projects/agentflow && git status`
Expected: Clean working tree (everything committed in prior tasks)

**Step 2: Verify final structure**

Run: `find /Users/brycelivesey/Projects/agentflow -not -path '*/.git/*' -not -path '*/.git' | sort`
Expected:
```
agentflow/
agentflow/docs/
agentflow/docs/plans/
agentflow/docs/plans/2026-02-27-planning-meeting-skill-design.md
agentflow/docs/plans/2026-02-27-planning-meeting-skill-impl.md
agentflow/install.sh
agentflow/skills/
agentflow/skills/planning-meeting/
agentflow/skills/planning-meeting/SKILL.md
agentflow/templates/
agentflow/templates/plan-output.md
```
