# Execute Plan Task Skill

## User Story
Create one reusable skill that takes a planned task and runs a disciplined multi-agent implementation workflow (implement, review, test, document), then creates a PR package and opens the PR for human review.

## Context
- Existing planning workflow is defined in `skills/planning-meeting/SKILL.md` and outputs stacked tasks.
- Prior design notes explicitly identified this as the next phase: `docs/plans/2026-02-27-planning-meeting-skill-design.md`.
- Desired workflow is Facebook-style small diffs with strong verification and documentation.
- Orchestration preference is Claude team-style execution with isolated contexts per role.
- Skill must be reusable across repositories, so CI is deferred in v1 instead of hardcoded.

## Discussion Summary
- Use one skill (not split skills) so task context stays unified during execution.
- Use role-based agents to reduce tunnel vision and enforce collaboration.
- Generate architecture and decision artifacts so humans can review outcomes without deep code spelunking.
- PR creation is allowed automatically.
- Human approval is required for accepting/merging the PR, not for creating it.
- CI command standardization is intentionally deferred for now to preserve portability.

## Approach
Create a new skill `execute-plan-task` that executes one task from a plan through an orchestrated role workflow:
1. Resolve selected task and acceptance criteria from `.agentflow/plans/...`.
2. Implement change (`implementer`).
3. Perform independent quality/security/regression review (`reviewer`).
4. Run task-scoped validation commands available in repo context (`tester`).
5. Produce decision and architecture artifacts (`reporter`).
6. Iterate until gates pass or fail with explicit reason.
7. Generate PR-ready summary and create PR automatically.

The skill remains repo-agnostic by treating CI as a future extension and requiring explicit documentation of what was verified.

### Alternatives Considered
1. Split into two or more skills (`execute` vs `report`/`pr`).
- Not chosen because it introduces context handoff overhead and weaker end-to-end guarantees.

2. Include mandatory CI configuration in v1.
- Not chosen because repository variability would make early adoption brittle.

3. Require human approval before PR creation.
- Not chosen because automatic PR creation is acceptable; human approval is still required at merge/review stage.

## Tasks

### Task 1: Define Execution Contract
- **Description:** Define inputs, outputs, statuses, and non-negotiable gates for a single-task run.
- **Acceptance Criteria:** Contract specifies task selection, retry/stop behavior, required artifacts, and success/failure states.
- **Dependencies:** None
- **Files likely affected:** `skills/execute-plan-task/SKILL.md`
- **Layer:** infra

### Task 2: Scaffold Skill and Trigger Metadata
- **Description:** Create `execute-plan-task` skill directory and frontmatter with robust trigger wording.
- **Acceptance Criteria:** Skill triggers on plan execution requests and clearly scopes to one task at a time.
- **Dependencies:** Task 1
- **Files likely affected:** `skills/execute-plan-task/SKILL.md`
- **Layer:** infra

### Task 3: Encode Multi-Agent Role Workflow
- **Description:** Define responsibilities and handoffs for implementer, reviewer, tester, and reporter.
- **Acceptance Criteria:** Workflow documents role outputs, sequencing, conflict resolution, and escalation/fail conditions.
- **Dependencies:** Task 2
- **Files likely affected:** `skills/execute-plan-task/SKILL.md`
- **Layer:** infra

### Task 4: Specify Artifact Outputs
- **Description:** Standardize generated artifacts for human-readable review of decisions and architecture.
- **Acceptance Criteria:** Skill requires output under `.agentflow/artifacts/<YYYY-MM-DD>-<task-slug>/` with:
  - `adr.md`
  - `implementation-report.md`
  - `architecture-diagram.txt`
  - `verification.md`
- **Dependencies:** Task 3
- **Files likely affected:** `skills/execute-plan-task/SKILL.md`
- **Layer:** docs

### Task 5: Add PR Creation Workflow
- **Description:** Define final packaging flow that prepares branch/summary and creates the PR automatically.
- **Acceptance Criteria:** Skill creates PR with artifact-based summary and explicitly marks status as awaiting human review/merge approval.
- **Dependencies:** Task 3, Task 4
- **Files likely affected:** `skills/execute-plan-task/SKILL.md`
- **Layer:** infra

### Task 6: Defer CI With Explicit TODO Hooks
- **Description:** Include a dedicated section for future repo-specific CI integration.
- **Acceptance Criteria:** Skill records CI as deferred in v1 and provides placeholders for future config-driven commands.
- **Dependencies:** Task 3
- **Files likely affected:** `skills/execute-plan-task/SKILL.md`
- **Layer:** infra

### Task 7: Install and Validate
- **Description:** Ensure installation flow exposes the new skill and validate skill integrity.
- **Acceptance Criteria:** `install.sh` includes new skill symlink and validation/smoke checks pass.
- **Dependencies:** Task 2, Task 3, Task 4, Task 5, Task 6
- **Files likely affected:** `install.sh`
- **Layer:** test

## Open Questions
- What default behavior should tester use when no obvious task-scoped command exists in a repo?
- What PR metadata conventions should be standardized later (labels, reviewers, templates)?
- What schema should future CI config use when CI integration is added?
