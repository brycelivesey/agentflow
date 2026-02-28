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

Tasks are tracked as GitHub Issues using the `task` issue template.
Each task issue includes: Description, Acceptance Criteria, Dependencies, Files Likely Affected, and Layer.

### Status Labels

| Label | Meaning |
|-------|---------|
| `status:todo` | Task is defined but not yet started |
| `status:in-progress` | Task is actively being worked on |
| `status:blocked` | Task cannot proceed (dependency unmet or other blocker) |

### Dependency Encoding

Dependencies between tasks are encoded in each issue's **Dependencies** field
using GitHub issue references: `#<number>`, comma-separated.

Example: `#1, #3` means the task depends on issues #1 and #3 being completed first.
`None` means the task has no dependencies.

### Task List

| Task | Issue | Status | Dependencies |
|------|-------|--------|--------------|
| Task 1: [Name] | #TBD | `status:todo` | None |
| Task 2: [Name] | #TBD | `status:todo` | #TBD |
...

## Open Questions
[Anything unresolved that might come up during implementation]
