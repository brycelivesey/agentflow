# AGENTS.md

Instructions for AI coding agents working in this repository.

## Project Purpose

Agentflow provides reusable skills for AI coding agents (Claude Code, Codex, and others). Skills are self-contained instruction sets that agents invoke to perform structured workflows.

## Repo Structure

```
install.sh                          # Installs skills via symlinks
skills/
  planning-meeting/SKILL.md         # Collaborative planning skill
  execute-plan-task/SKILL.md        # Task execution skill
templates/
  plan-output.md                    # Plan document template
.gitignore                          # Excludes plans and artifacts
```

## How Skills Work

Each skill is a directory under `skills/` containing a `SKILL.md` file. The `SKILL.md` uses YAML frontmatter with two required fields:

```yaml
---
name: skill-name
description: When and how the skill triggers.
---
```

The body of `SKILL.md` contains the full instructions the agent follows when the skill is invoked.

### Installation

Run `./install.sh` to symlink all skills into the agent-specific directories:

- Claude Code: `~/.claude/skills/<skill-name>`
- Codex: `~/.agents/skills/<skill-name>`

The installer validates that each skill directory exists and its `SKILL.md` has the required `name:` frontmatter before creating symlinks.

## Workflow: Planning then Execution

Agentflow uses a two-phase workflow:

1. **planning-meeting** -- Conduct a collaborative planning session that produces a plan document with small, stacked tasks. Plans are written to `.agentflow/plans/YYYY-MM-DD-<feature-name>.md` in the target project.

2. **execute-plan-task** -- Execute one task from a plan through a multi-agent workflow (implement, review, test, document) and create a PR. Invoke once per task, in dependency order.

## Plans and Artifacts

Plans and execution artifacts are local working state, not committed to version control.

- **Plans:** `.agentflow/plans/` (gitignored)
- **Artifacts:** `.agentflow/artifacts/` (gitignored)

These directories exist in the target project where skills are invoked, not in this repo.

## Development Principles

This project follows trunk-based development:

- One logical change per commit/PR
- Small diffs, reviewable in roughly 15 minutes
- All PRs target `main`
- No long-lived feature branches

## Adding a New Skill

1. Create a directory under `skills/` with the skill name (lowercase, hyphenated).
2. Add a `SKILL.md` with YAML frontmatter (`name:` and `description:`) and the skill instructions in the body.
3. Add the skill name to the `SKILLS` array in `install.sh`.
4. Run `./install.sh` to verify it installs correctly.

## Modifying an Existing Skill

Edit the `SKILL.md` directly. Since installation uses symlinks, changes take effect immediately for any agent using the installed skill. No reinstall is needed.

## Templates

Shared templates live in `templates/`. Skills reference these templates by convention. Currently:

- `templates/plan-output.md` -- Structure for plan documents produced by `planning-meeting`.

## Things to Avoid

- Do not commit plan files or execution artifacts to this repo.
- Do not add user-specific paths or configuration.
- Do not add private or internal-only references.
- Keep skill instructions self-contained within their `SKILL.md`.
