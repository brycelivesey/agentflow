---
name: execute-plan-task
description: Use when executing one GitHub Issue task created by the planning-meeting skill. This skill runs one issue at a time through a strict sequential workflow (implement, reflect/refactor, review, test, summarize) and creates a PR with a concise trust-focused summary. Triggers on phrases like "execute task", "run task", "start task", "implement task", "work on issue #N", or "execute issue N".
---

# Execute Plan Task

## Overview

Execute exactly one GitHub Issue task through a sequential multi-role workflow:

`implementer -> retrospective/refactor gate -> reviewer -> tester -> reporter`

Issue-only contract:
- Input is a GitHub Issue number/URL, not a markdown plan file.
- The issue body must follow `templates/github-issue-task.md`.
- The PR summary must be concise and trust-focused.

Scope:
- One issue per invocation.
- To execute multiple tasks, run this skill once per issue in dependency order.

## Required Execution Mode

Use sequential sub-agent orchestration only:
- Spawn one role at a time in strict order.
- Wait for each role to finish before continuing.
- Keep one active role thread unless the user explicitly requests parallel execution.
- Do not advance to reviewer until the retrospective/refactor gate has passed.

For each role handoff, pass a compact context packet containing:
- Issue metadata (description, acceptance criteria, dependencies, layer, file hints)
- Current branch and diff status
- Retrospective outcome (difficulty, refactor decision, and follow-up if deferred)
- Reviewer flow diagram once available (for reporter reuse)
- Inputs needed by the next role
- Exact expected output format and pass/fail criteria

## Inputs

| Input | Required | Description |
|---|---|---|
| Issue identifier | Yes | GitHub issue number or URL for one executable task |
| Working branch | Yes | Current branch, or auto-create from `origin/main` when on `main` |

## Preflight (Required)

Run and require success:

```bash
gh auth status
gh repo view --json nameWithOwner,defaultBranchRef
```

Stop immediately on failure.

## Resolve the Task from Issue (Required)

Read the issue:

```bash
gh issue view <issue_number> --json number,title,body,url,state,labels
```

Extract from issue body:
- `## Description`
- `## Acceptance Criteria`
- `## Dependencies`
- `## Layer`
- `## File Hints`
- `## Status Labels`

Use `templates/github-issue-task.md` as the canonical contract.

### Schema gate

Before implementation, validate the issue body schema. Required checks:
- All required section headers exist.
- `## Layer` is one of `data|api|ui|test|infra`.
- `## Dependencies` uses only `- none` or `- #<issue_number>` and no duplicates.
- `## Status Labels` has exactly one entry from `status:todo|status:in-progress|status:done`.

If schema validation fails, stop and report the exact failure.

### Dependency gate

Parse dependency issue numbers from `## Dependencies`.

For each dependency issue `#N`, require:

```bash
gh issue view N --json state,labels
```

A dependency is satisfied only if:
- `state` is `CLOSED`, and
- labels include `status:done`.

If any dependency is not satisfied, stop and report which dependency blocks execution.

### Status gate

The task issue must carry exactly one status label.

At start of execution, set status to `status:in-progress`:

```bash
gh issue edit <issue_number> \
  --remove-label status:todo \
  --add-label status:in-progress
```

If the issue already has `status:in-progress`, continue.
If it has `status:done`, stop and ask whether execution should be skipped.

## Outputs

A successful run produces:
- Implementation commits on a working branch
- One concise summary file at `.agentflow/artifacts/<YYYY-MM-DD>-issue-<number>/execution-summary.md`
- One GitHub PR targeting `main`
- One issue comment linking to the PR

Artifact locality:
- `.agentflow/artifacts/` files are local working state (gitignored)
- Do not commit artifact files

## Retrospective/Refactor Gate (Required)

Run this gate immediately after implementer output and before reviewer handoff.

Checklist (required):
- Rate implementation difficulty as `low|medium|high` with one concrete reason.
- State one thing that could have been simpler or cleaner.
- Decide `refactor-now: yes|no`.

Decision policy:
- If `refactor-now: yes`, apply the smallest in-scope refactor immediately, then refresh implementation notes before reviewer/tester.
- If a refactor is valuable but out of scope or high-risk for this issue, keep the current diff scoped and record a concrete follow-up issue suggestion.

Gate output format:
- `difficulty: <low|medium|high> - <reason>`
- `simpler-path: <concrete improvement>`
- `refactor-now: <yes|no>`
- `refactor-summary: <what changed or why deferred>`

## Non-Negotiable Gates

All gates must pass before creating the PR:

1. Acceptance criteria are demonstrably met.
2. No regressions are introduced.
3. No new security vulnerabilities are introduced.
4. Diff is scoped to the issue (no unrelated changes).
5. Summary is concise and includes the required trust sections.
6. Retrospective/refactor gate is completed; required in-scope refactors are applied.
7. Reviewer output includes a simple ASCII/pseudocode data-flow diagram.

## Roles

### Implementer

Mandate:
- Implement the issue with the smallest coherent diff.

Responsibilities:
- Follow repository conventions and existing architecture.
- Keep changes scoped to issue acceptance criteria.
- Produce brief implementation notes for handoff.
- Run the retrospective checklist and apply any required in-scope refactor before reviewer handoff.

Boundaries:
- Do not self-approve quality gates.
- Do not produce final summary.

### Reviewer

Mandate:
- Independently verify correctness and codebase fit.

Responsibilities:
- Verify every acceptance criterion.
- Check regressions and security concerns.
- Check architectural fit with existing system (integration points, pattern consistency, layering).
- Check diff scope cleanliness.
- Provide a simple ASCII/pseudocode diagram of the changed data/control flow so humans can review architecture without reading source code.
- Return verdict: `pass` or `fail` with actionable issues.

Boundaries:
- Do not edit code.
- Do not run the test suite.

Reviewer output format (required):
- `Verdict: pass|fail`
- `Findings: <none or actionable list>`
- `AC coverage: <AC-by-AC check>`
- `Flow diagram (required):` one fenced `text` block that:
  - stays quick to read (target ~3-5 minutes to understand)
  - is accurate to the implemented flow/architecture
  - includes enough detail to explain impacted components and boundaries
  - stays focused on changed/impacted paths rather than the full system

### Tester

Mandate:
- Validate behavior through execution.

Responsibilities:
- Discover available test commands.
- Run relevant tests for changed scope.
- If no formal tests exist, run best-available manual/structural checks.
- Return verdict: `pass` or `fail` with command-level results.

Boundaries:
- Do not modify code.

### Reporter

Mandate:
- Produce a short trust summary so humans can review quickly.

Responsibilities:
- Build `execution-summary.md` with required sections.
- Keep the summary skimmable and concrete.
- Favor bullets over long paragraphs.
- Include the reviewer-provided flow diagram verbatim in the `Flow Diagram` section.

Boundaries:
- Do not modify code.
- Do not fabricate verification results.

## Iteration Policy

On reviewer/tester failure:
- Return to implementer with specific findings.
- Re-run reviewer and tester gates after fixes.
- Maximum 3 cycles.

On retrospective gate outcome:
- If `refactor-now: yes`, return to implementer for the refactor before reviewer/tester.
- After refactor changes, re-run reviewer and tester gates.

Stop as `failed` if:
- Dependency gate fails
- Issue schema is invalid
- Acceptance criteria are ambiguous/contradictory
- Fundamental architectural conflict requires re-planning
- Iteration budget is exhausted

On failure:
- Write `.agentflow/artifacts/<YYYY-MM-DD>-issue-<number>/failure-report.md`
- Comment failure summary on the issue
- Do not create a PR

## Concise Summary Contract (Required)

The reporter must produce this exact structure in `execution-summary.md`:

```markdown
# Execution Summary: Issue #<number> - <title>

## System Fit
- Where this change plugs into the existing architecture.
- What existing components/interfaces were reused.

## Data Flow
- Before: <short path/behavior>
- After: <short path/behavior>
- Impacted boundaries: <api/db/queue/ui/etc>

## Decision and Alternatives
- Chosen approach: <what and why>
- Alternative considered: <option>
- Why not chosen: <tradeoff>

## Complexity and Tradeoffs
- Runtime complexity: <if relevant>
- Space complexity: <if relevant>
- Implementation complexity: <low/medium/high and why>
- Key tradeoff: <simplicity vs efficiency, etc>

## Flow Diagram
- High-level changed path from reviewer output (ASCII/pseudocode).
- Keep simple and human-scannable while preserving enough detail for architectural understanding.
- Target a diagram that can be understood in roughly 3-5 minutes without reading source code.

## Verification
- Reviewer verdict: <pass/fail>
- Tester verdict: <pass/fail>
- Retrospective: <difficulty + refactor decision>
- Commands run: <command + result>
- Residual risks: <what remains unverified>
```

Guidance:
- Keep it concise and scannable.
- No strict line cap, but do not write long narrative sections.
- Include only decision-relevant detail.

## PR Packaging Workflow

After all gates pass:

1. Prepare branch

If current branch is `main`, create a feature branch from `origin/main` using a task slug.

2. Commit scoped changes

Commit only files required for this issue.

3. Assemble PR body from summary

Use `execution-summary.md` as the primary body content.

Suggested PR body layout:

```markdown
## Summary
<2-4 sentence plain-language summary>

## Trust Snapshot
<content from execution-summary.md sections>

---
Source issue: #<number> <issue_url>
```

4. Create PR

```bash
gh pr create \
  --title "<type>: <issue title>" \
  --body-file <assembled-pr-body-file> \
  --base main \
  --head <branch-name>
```

5. Link PR back to issue

```bash
gh issue comment <issue_number> --body "Opened PR: <pr_url>"
```

6. Status after PR creation

- Keep issue at `status:in-progress` while PR is under review.
- Move to `status:done` only after human acceptance/merge.

## Failure Policy

Fail fast on any of:
- Preflight command failures
- Issue schema validation failures
- Dependency gate failures
- Required review/test gate failures after max iterations
- PR creation failure

Failure report must include:
- Failed command or gate
- Error category (`auth|network|permissions|schema|dependency|test|review|other`)
- Suggested corrective action

## Key Principles

- Execute one issue at a time.
- Optimize for trust and reviewer speed.
- Prioritize architectural fit and data-flow clarity over verbose narration.
- Keep summaries concise, concrete, and decision-oriented.
