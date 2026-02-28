# Agentflow

Reusable skills for AI coding agents. Plan features collaboratively, then execute tasks through a structured multi-agent workflow that produces reviewed, documented pull requests.

## Prerequisites

- macOS or Linux
- [Claude Code](https://docs.anthropic.com/en/docs/claude-code) or [Codex](https://github.com/openai/codex) installed
- [GitHub CLI](https://cli.github.com/) (`gh`) authenticated (required for PR creation)
- Git

## Install

```bash
git clone https://github.com/brycelivesey/agentflow.git
cd agentflow
./install.sh
```

This symlinks skills into `~/.claude/skills` and `~/.agents/skills`. Both Claude Code and Codex will pick them up automatically.

## Usage

### Plan a feature

Start a planning meeting to break work into small, stacked tasks:

```
/planning-meeting
```

The skill guides a collaborative conversation and produces a plan file in `.agentflow/plans/`.

### Execute a task

Run a single task from a plan through implementation, review, testing, and documentation:

```
/execute-plan-task <plan-name> task <N>
```

This creates a feature branch, implements the task, and opens a PR for human review.

## Included Skills

| Skill | Trigger | Description |
|-------|---------|-------------|
| `planning-meeting` | `/planning-meeting` | Break a feature into small, reviewable tasks for trunk-based development |
| `execute-plan-task` | `/execute-plan-task` | Execute one task through a multi-agent workflow (implement, review, test, document) and create a PR |

## Project Structure

```
agentflow/
├── install.sh              # Symlinks skills into agent tool directories
├── skills/
│   ├── planning-meeting/   # Collaborative feature planning skill
│   │   └── SKILL.md
│   └── execute-plan-task/  # Task execution and PR creation skill
│       └── SKILL.md
└── templates/
    └── plan-output.md      # Template for plan file structure
```

## License

MIT
