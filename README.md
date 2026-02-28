# agentflow

Reusable CLI skills for structured, agent-driven development workflows. Break features into small tasks, then execute each task through an automated implement-review-test-document cycle.

## Prerequisites

- [Claude Code](https://docs.anthropic.com/en/docs/claude-code) or a compatible agent CLI that supports `~/.agents/skills/`
- Bash shell
- Git
- [GitHub CLI](https://cli.github.com/) (`gh`) — used by `execute-plan-task` to create pull requests

## Install

Clone the repo and run the install script:

```bash
git clone <repo-url> agentflow
cd agentflow
./install.sh
```

This symlinks each skill into both `~/.claude/skills/` and `~/.agents/skills/` so they are available as slash commands in your agent CLI.

## Usage

### Plan a feature

Start a planning meeting to break a feature into small, stacked tasks:

```
/planning-meeting
```

The skill guides a collaborative conversation and outputs a plan file to your project's `.agentflow/plans/` directory.

### Execute a task

Run a single task from a plan through the full workflow (implement, review, test, document) and create a PR:

```
/execute-plan-task 1
```

Specify the task number (or name) from the plan. The skill enforces quality gates at each stage and produces artifacts alongside the code change.

## Included Skills

| Skill | Command | Purpose |
|-------|---------|---------|
| **planning-meeting** | `/planning-meeting` | Break a feature into small, reviewable tasks |
| **execute-plan-task** | `/execute-plan-task N` | Execute one task through implement-review-test-document and open a PR |

## Project Structure

```
agentflow/
  install.sh              # Symlinks skills into agent CLI directories
  skills/
    planning-meeting/     # Planning conversation skill
    execute-plan-task/    # Task execution workflow skill
  templates/
    plan-output.md        # Template for plan documents
```
