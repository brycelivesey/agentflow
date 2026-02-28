---
name: execute-plan-task
description: Use when executing a planned task from an agentflow plan. This skill runs one task at a time through a disciplined multi-agent workflow (implement, review, test, document) and creates a PR for human review. Triggers on phrases like "execute task", "run task", "start task", "implement task", "execute plan task", "work on task N".
---

# Execute Plan Task

## Overview

Execute exactly **one task** from an `.agentflow/plans/` plan file through an orchestrated multi-agent workflow. Each run takes a single task through implementation, independent review, testing, artifact generation, and PR creation. The skill enforces quality gates at every stage and produces human-reviewable artifacts alongside the code change.

**Scope:** One task per invocation. To execute multiple tasks, invoke this skill once per task in dependency order.

## Execution Contract

This section defines the inputs, outputs, statuses, and non-negotiable gates for a single-task execution run.

### Inputs

| Input | Source | Required | Description |
|-------|--------|----------|-------------|
| Plan file | `.agentflow/plans/<YYYY-MM-DD>-<feature-name>.md` | Yes | The plan containing the task to execute |
| Task identifier | User specifies (e.g., "task 1", "Task 3: Encode Multi-Agent Role Workflow") | Yes | Which task within the plan to execute |
| Working branch | Current branch or created from `main` | Yes | The branch where implementation happens |

**Task resolution:** The skill reads the specified plan file, locates the task by number or name, and extracts:
- Description
- Acceptance criteria
- Dependencies
- Files likely affected
- Layer

**Dependency check:** Before execution begins, verify all listed dependencies are satisfied. A dependency is satisfied when its corresponding task has been merged to main or is present on the current branch. If unmet dependencies exist, stop and report which are missing.

### Outputs

Every successful run produces:

| Output | Location | Description |
|--------|----------|-------------|
| Implementation | Working branch commits | Code changes fulfilling the task |
| ADR | `.agentflow/artifacts/<YYYY-MM-DD>-<task-slug>/adr.md` | Architecture decision record for non-trivial choices made |
| Implementation report | `.agentflow/artifacts/<YYYY-MM-DD>-<task-slug>/implementation-report.md` | Summary of what was built, why, and how |
| Architecture diagram | `.agentflow/artifacts/<YYYY-MM-DD>-<task-slug>/architecture-diagram.txt` | Text-based diagram of affected components |
| Verification report | `.agentflow/artifacts/<YYYY-MM-DD>-<task-slug>/verification.md` | What was tested, how, and results |
| Pull request | GitHub PR | PR with artifact-based summary, awaiting human review |

### Statuses

A task run is always in exactly one of these states:

| Status | Meaning |
|--------|---------|
| `resolving` | Reading plan, extracting task, checking dependencies |
| `implementing` | Implementer agent is writing code |
| `reviewing` | Reviewer agent is performing quality/security/regression review |
| `testing` | Tester agent is running validation |
| `reporting` | Reporter agent is generating artifacts |
| `iterating` | Review or testing found issues; cycling back to implementer |
| `packaging` | Creating PR-ready branch, summary, and opening PR |
| `completed` | PR created, all gates passed, awaiting human review |
| `failed` | A non-negotiable gate failed after max retries, or an unrecoverable error occurred |

### Non-Negotiable Gates

These gates **must** pass before a run can reach `completed`. There are no overrides.

1. **Acceptance criteria met.** Every acceptance criterion listed in the task must be demonstrably satisfied. The reviewer confirms this independently from the implementer.

2. **No regressions introduced.** The reviewer verifies that existing functionality is not broken by the change. If test commands are available, the tester must run them and they must pass.

3. **No security vulnerabilities introduced.** The reviewer checks for OWASP top 10 and any context-specific security concerns. Any finding blocks completion.

4. **Artifacts generated.** All four artifact files must exist and contain substantive content (not stubs or placeholders).

5. **Clean diff.** The change is scoped to the task — no unrelated modifications, no leftover debug code, no commented-out blocks.

### Retry and Stop Behavior

**Retry policy:**
- When a gate fails, the run enters `iterating` status.
- The implementer receives specific feedback from the reviewer or tester describing what failed and why.
- The implementer makes targeted fixes and the review/test cycle repeats.
- **Maximum 3 iterations.** After 3 failed review/test cycles on the same gate, the run transitions to `failed`.

**Stop conditions (immediate `failed`, no retry):**
- Unmet task dependencies discovered after resolution.
- The task's acceptance criteria are ambiguous or contradictory (escalate to user).
- A fundamental architectural conflict is discovered that requires re-planning.
- The implementer determines the task is not achievable as scoped (escalate to user).

**On failure:**
- The run produces a failure report explaining what was attempted, what failed, and why.
- The failure report is written to `.agentflow/artifacts/<YYYY-MM-DD>-<task-slug>/failure-report.md`.
- No PR is created.
- The user is informed with a clear summary and recommended next steps (re-plan, adjust scope, or unblock dependencies).
