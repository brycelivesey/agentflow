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

## Multi-Agent Role Workflow

This skill uses four specialized roles executed sequentially within a single orchestrated run. Each role operates with a focused mandate and produces explicit outputs that feed into the next stage. The orchestrator (this skill) manages transitions, enforces gates, and handles iteration.

### Role Definitions

#### Implementer

**Mandate:** Write the code that fulfills the task's description and acceptance criteria. Nothing more, nothing less.

**Inputs:**
- Task description, acceptance criteria, and dependency context from the plan
- Files likely affected (as starting points, not constraints)
- Feedback from reviewer/tester (during iteration cycles)

**Responsibilities:**
- Read and understand the relevant codebase before writing any code
- Make the minimal change that satisfies all acceptance criteria
- Follow existing patterns and conventions in the repository
- Keep the diff scoped — no drive-by refactors, no unrelated cleanup
- During iteration: make targeted fixes based on specific reviewer/tester feedback

**Outputs:**
- Committed code changes on the working branch
- Brief implementation notes: what was changed and why (used by reviewer and reporter)

**Boundaries:**
- Does NOT self-review or self-test
- Does NOT generate artifacts
- Does NOT make architectural decisions that contradict the plan — if the plan seems wrong, escalate

#### Reviewer

**Mandate:** Independently verify the implementation meets all quality gates. The reviewer has NOT seen the implementation process — only the resulting diff and the task requirements.

**Inputs:**
- The full diff of changes on the working branch
- Task description and acceptance criteria from the plan
- Implementer's notes
- Repository context (existing code, patterns, conventions)

**Responsibilities:**
- Verify every acceptance criterion is demonstrably met
- Check for regressions — does the change break existing behavior?
- Check for security vulnerabilities (OWASP top 10, context-specific concerns)
- Verify the diff is clean — no debug code, no commented-out blocks, no unrelated changes
- Verify code follows repository conventions and patterns
- Produce a clear verdict: **pass** or **fail with specific issues**

**Outputs:**
- Review verdict: `pass` or `fail`
- If `fail`: a list of specific, actionable issues, each referencing the file and concern
- If `pass`: confirmation of which acceptance criteria were verified and how

**Boundaries:**
- Does NOT write or modify code
- Does NOT run tests (that's the tester's job)
- Does NOT soften findings — if something fails a gate, it fails
- Reviews the diff independently; does not defer to the implementer's notes for correctness

#### Tester

**Mandate:** Run available validation commands and verify the change works as intended through execution, not just inspection.

**Inputs:**
- The current state of the working branch
- Task description and acceptance criteria
- Repository context (available test commands, test frameworks, scripts)

**Responsibilities:**
- Discover available test commands (look for `package.json` scripts, `Makefile` targets, test directories, CI config)
- Run relevant test suites — prioritize tests related to the changed code
- If no formal test commands exist, perform manual verification where possible (e.g., syntax checks, dry runs, build commands)
- Report exactly what was run and what the results were
- Produce a clear verdict: **pass** or **fail with specific failures**

**Outputs:**
- Test verdict: `pass` or `fail`
- List of commands executed and their results (exit codes, relevant output)
- If `fail`: specific test failures with enough context for the implementer to fix them
- If no test commands are available: explicit statement of what was and wasn't verifiable

**Boundaries:**
- Does NOT write code or fix test failures (sends feedback to implementer)
- Does NOT write new tests unless the task's acceptance criteria explicitly require it
- Does NOT skip failing tests or mark known failures as acceptable

#### Reporter

**Mandate:** Produce the artifact package that allows a human to understand what was built, why decisions were made, and what was verified — without reading every line of code.

**Inputs:**
- Implementer's notes and the final diff
- Reviewer's verdict and findings
- Tester's verdict and execution results
- Task description and plan context

**Responsibilities:**
- Write `adr.md` — document non-trivial architectural or design decisions made during implementation. If no significant decisions were made, state that explicitly rather than inventing content.
- Write `implementation-report.md` — summarize what was built, how it fits into the existing system, and any notable implementation details.
- Write `architecture-diagram.txt` — text-based diagram showing affected components and their relationships.
- Write `verification.md` — consolidate what the reviewer checked, what the tester ran, and the results.
- All artifacts go to `.agentflow/artifacts/<YYYY-MM-DD>-<task-slug>/`

**Outputs:**
- Four artifact files with substantive content (no stubs, no placeholders)

**Boundaries:**
- Does NOT modify code
- Does NOT re-run tests or re-review code
- Does NOT fabricate results — only documents what actually happened

### Workflow Sequencing

```
┌─────────────┐
│  resolving   │  Read plan, extract task, check dependencies
└──────┬──────┘
       │
       ▼
┌─────────────┐
│ implementing │  Implementer writes code
└──────┬──────┘
       │
       ▼
┌─────────────┐
│  reviewing   │  Reviewer inspects diff independently
└──────┬──────┘
       │
       ├── pass ──► tester
       │
       └── fail ──► iterating (back to implementer with feedback)
                         │
                         ▼
                    implementer → reviewer (repeat, max 3 cycles)
       │
       ▼
┌─────────────┐
│   testing    │  Tester runs validation commands
└──────┬──────┘
       │
       ├── pass ──► reporter
       │
       └── fail ──► iterating (back to implementer with feedback)
                         │
                         ▼
                    implementer → reviewer → tester (repeat, max 3 cycles total)
       │
       ▼
┌─────────────┐
│  reporting   │  Reporter generates artifacts
└──────┬──────┘
       │
       ▼
┌─────────────┐
│  packaging   │  Create PR with artifact-based summary
└──────┬──────┘
       │
       ▼
┌─────────────┐
│  completed   │  PR created, awaiting human review
└─────────────┘
```

**Key sequencing rules:**
1. Roles execute strictly in order: implementer → reviewer → tester → reporter.
2. The reviewer never sees the implementation in progress — only the finished diff.
3. The tester only runs after the reviewer passes. No point testing code that fails review.
4. The reporter only runs after both reviewer and tester pass. Artifacts reflect the final state.
5. Iteration cycles always restart at the implementer and proceed forward through the gates again.

### Iteration and Conflict Resolution

**Iteration triggers:**
- Reviewer returns `fail` → implementer receives the specific issues and fixes them, then the diff goes back to the reviewer.
- Tester returns `fail` → implementer receives the specific failures and fixes them, then the full review → test cycle repeats.

**Iteration budget:**
- Maximum **3 iteration cycles** total across all gates combined. An iteration cycle is one round-trip from implementer back through the failing gate.
- The counter is shared — 2 review failures + 1 test failure = 3 cycles = budget exhausted.

**Conflict resolution:**
- If the reviewer and implementer disagree on whether a finding is valid, the reviewer's judgment prevails. The reviewer is the independent check.
- If the implementer believes a reviewer finding is incorrect, the implementer must address it anyway or escalate to the user. The implementer cannot override the reviewer.
- If the tester reports a failure that the implementer believes is a pre-existing issue (not caused by this change), the implementer must document this claim with evidence (e.g., showing the same failure exists on main). The orchestrator then asks the user whether to proceed or stop.

**Escalation to user:**
- Ambiguous or contradictory acceptance criteria
- Fundamental architectural conflict with the plan
- Disagreement that cannot be resolved within the iteration budget
- Pre-existing failures disputed between tester and implementer
- Task determined to be unachievable as scoped

### Failure Conditions

The run transitions to `failed` immediately (no further iteration) when:

1. **Iteration budget exhausted.** Three cycles completed without all gates passing.
2. **Unmet dependencies discovered.** A required prior task has not been completed.
3. **Unresolvable scope conflict.** The task requires changes that fundamentally conflict with the existing architecture or plan.
4. **User-directed stop.** The user explicitly halts execution after an escalation.

On failure, the orchestrator:
- Stops all role activity
- Writes a failure report to `.agentflow/artifacts/<YYYY-MM-DD>-<task-slug>/failure-report.md`
- Does NOT create a PR
- Reports to the user: what was attempted, what failed, why, and recommended next steps

## Artifact Specifications

All artifacts are written to `.agentflow/artifacts/<YYYY-MM-DD>-<task-slug>/` where the date is the execution date and the task slug is derived from the task name (lowercase, hyphens, no special characters). Artifacts are the primary mechanism for human reviewers to understand what happened without reading every line of code or diff.

**Quality bar:** Every artifact must contain substantive content specific to the task. Stubs, placeholders, boilerplate-only files, or "N/A" sections fail the artifact gate. If a section genuinely does not apply, state why in one sentence.

### `adr.md` — Architecture Decision Record

Documents non-trivial technical decisions made during implementation. Uses a structured format so decisions are discoverable and reviewable over time.

```markdown
# ADR: <concise decision title>

## Status
Accepted

## Context
<What problem or question arose during implementation? What constraints
applied? Reference the task and plan for background.>

## Decision
<What was decided and why. Be specific — name the pattern, library,
approach, or tradeoff chosen.>

## Alternatives Considered
<List alternatives that were evaluated. For each, one sentence on why
it was not chosen.>

## Consequences
<What this decision enables, what it constrains, and any follow-up
work it creates.>
```

**Multiple decisions:** If the task required multiple non-trivial decisions, include multiple ADR blocks in the same file, each with its own title.

**No significant decisions:** If the implementation was straightforward with no meaningful design choices, write a single brief ADR stating: what the task was, that the implementation followed existing patterns with no new decisions required, and reference which existing patterns were followed.

### `implementation-report.md` — Implementation Report

Summarizes what was built so a reviewer can understand the change at a high level before (or instead of) reading the full diff.

```markdown
# Implementation Report: <task name>

## Summary
<2-4 sentences: what was built and why, in plain language.>

## Changes

### <file or component name>
- <What changed and why>

### <file or component name>
- <What changed and why>

<Repeat for each file or logical group of changes.>

## How It Works
<Explain the runtime behavior or integration of the change. How does a
user or system interact with what was built? Keep this concrete.>

## Scope and Boundaries
- **In scope:** <what this change covers>
- **Out of scope:** <what this change intentionally does not cover>
- **Assumptions:** <any assumptions the implementation relies on>
```

**Granularity:** Group changes by logical component, not by individual line edits. A reviewer should finish this file knowing *what changed at a system level* and *why each change was necessary*.

### `architecture-diagram.txt` — Architecture Diagram

A text-based diagram showing how the changed components relate to each other and to the broader system. This file uses plain ASCII or Unicode box-drawing characters so it renders correctly everywhere.

**Requirements:**
- Show the components that were added or modified by this task
- Show how they connect to existing components they interact with
- Label relationships (e.g., "reads from", "calls", "extends", "imports")
- Mark new or modified components distinctly (e.g., prefix with `[NEW]` or `[MODIFIED]`)
- Keep it focused on the task scope — this is not a full system architecture diagram

**Example structure:**
```
[NEW] skills/execute-plan-task/SKILL.md
    ├── reads from ──► .agentflow/plans/*.md
    ├── writes to ──► .agentflow/artifacts/<date>-<slug>/
    └── triggers ──► gh pr create

[MODIFIED] install.sh
    └── symlinks ──► skills/execute-plan-task/
```

**Diagram scope:** If the task only touches a single file with no cross-component interaction, the diagram should still show that file's role in the broader system context — where it sits, what reads it, what it affects.

### `verification.md` — Verification Report

Consolidates everything that was checked and tested, providing an auditable record of quality verification.

```markdown
# Verification Report: <task name>

## Review Summary
- **Verdict:** <pass/fail>
- **Reviewer findings:** <summary of what the reviewer checked and confirmed>
- **Acceptance criteria verification:**
  - [ ] <criterion 1> — <how it was verified>
  - [ ] <criterion 2> — <how it was verified>

## Test Summary
- **Verdict:** <pass/fail>
- **Commands executed:**
  - `<command>` — <result (pass/fail, exit code)>
  - `<command>` — <result>
- **Coverage notes:** <what was and wasn't testable>

## Security Check
- <What was checked and the result. Reference specific concerns if any were found and resolved.>

## Iteration History
<If iterations occurred, document each cycle:>
- **Cycle N:** <what failed, what was fixed, outcome of re-review/re-test>

<If no iterations occurred:>
- No iterations required. All gates passed on first cycle.

## Limitations
<Anything that could not be verified and why. E.g., "No integration test suite exists; verification was limited to static review and syntax checks.">
```

**Honesty over completeness:** If something could not be tested or verified, say so. A verification report that claims full coverage when the repo has no tests is worse than one that explicitly states its limitations.

### `failure-report.md` — Failure Report (failure runs only)

Written only when a run transitions to `failed` status. This is not produced by the reporter role — it is written by the orchestrator directly.

```markdown
# Failure Report: <task name>

## Failure Reason
<One sentence: why the run failed.>

## What Was Attempted
<Summary of implementation work completed before failure.>

## Iteration History
- **Cycle N:** <what was tried, what failed, feedback given>

## Root Cause Analysis
<Why the failure occurred. Distinguish between: task scoping issues,
implementation difficulty, pre-existing problems, or ambiguous requirements.>

## Recommended Next Steps
<Actionable suggestions: re-scope the task, fix a dependency, clarify
requirements, or re-plan.>
```

### Artifact Naming Convention

The artifact directory name follows this pattern:

```
.agentflow/artifacts/<YYYY-MM-DD>-<task-slug>/
```

- **Date:** The date execution started (not when the PR is created)
- **Task slug:** Derived from the task name by: lowercasing, replacing spaces with hyphens, removing special characters, and truncating to 50 characters
- **Examples:**
  - Task "Define Execution Contract" → `2026-02-28-define-execution-contract/`
  - Task "Scaffold Skill and Trigger Metadata" → `2026-02-28-scaffold-skill-and-trigger-metadata/`

## CI Integration (Deferred — v1)

Continuous integration is intentionally **not included** in v1 of this skill. Repository CI configurations vary widely (GitHub Actions, CircleCI, Jenkins, Makefiles, custom scripts), and hardcoding assumptions would make the skill brittle across different projects.

**What the tester does today (v1):**
- Discovers and runs test commands available locally (package.json scripts, Makefile targets, test directories)
- Reports exactly what was and wasn't verifiable
- Documents gaps explicitly in the verification report

**What CI integration will add (future):**
- Trigger repo-specific CI pipelines after implementation
- Wait for CI results before advancing through gates
- Include CI output in the verification report and PR summary

### CI Configuration Placeholder

When CI integration is added, it will be driven by an optional config section in the plan file or a repo-level `.agentflow/ci.yml` file. The expected schema:

```yaml
# .agentflow/ci.yml (future — not yet implemented)
# TODO: Define and implement CI integration

ci:
  # Command to run the full CI pipeline locally or trigger it remotely
  run: ""
  # Example values:
  #   "npm test"
  #   "make ci"
  #   "gh workflow run ci.yml && gh run watch"

  # How to check if CI passed (exit code 0 = pass)
  check: ""
  # Example values:
  #   "npm test"
  #   "gh run view --exit-status"

  # Timeout in seconds before treating CI as failed
  timeout: 600

  # Whether CI must pass before PR creation (vs. advisory-only)
  required: true
```

### Integration Points

When implemented, CI hooks into the workflow at two points:

1. **Post-tester, pre-reporter.** After local tests pass, trigger CI. If CI fails, enter `iterating` and send failures back to the implementer (counts against the iteration budget).

2. **Post-packaging (advisory).** If `required: false`, CI runs after PR creation and results are added as a PR comment rather than blocking the workflow.

### Until Then

The tester role remains the sole validation stage. The verification report must explicitly state:
- "CI integration is not configured for this repository."
- What local validation was performed as a substitute.
- Any test coverage gaps the human reviewer should be aware of.
