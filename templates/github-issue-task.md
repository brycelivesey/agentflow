# GitHub Issue Task Contract

Use this template for exactly one executable task. All sections are required.

## Canonical Issue Body Template

```md
## Description
<1-3 sentences describing the task outcome and scope>

## Acceptance Criteria
- [ ] <observable outcome 1>
- [ ] <observable outcome 2>

## Dependencies
- none

## Layer
api

## File Hints
- path/to/file.ext
- path/to/related-dir/

## Status Labels
- status:todo
```

## Dependency Syntax Rules (Deterministic)

Automation must parse dependencies only from the `## Dependencies` section.

1. Allowed list item forms are exact and case-sensitive:
- `- none`
- `- #<issue_number>` where `<issue_number>` matches `^[1-9][0-9]*$`
2. If `- none` is used, it must be the only dependency line.
3. If `- #<issue_number>` is used, include one issue reference per line.
4. Dependency references must be unique within the section.
5. Any dependency text outside `## Dependencies` is informational and must be ignored by automation.

## Layer Contract

`## Layer` must contain exactly one of:
- `data`
- `api`
- `ui`
- `test`
- `infra`

## File Hints Contract

`## File Hints` is a list of repository-relative paths, one path per bullet.

- Paths are hints for implementation and review.
- Paths do not override acceptance criteria or expand task scope.

## Status Label Contract

Exactly one status label must be present on the issue at all times:

- `status:todo` - task is ready to be claimed
- `status:in-progress` - task is actively being implemented
- `status:done` - task is complete and accepted

Allowed transitions: `status:todo -> status:in-progress -> status:done`

## Valid Example (Single Executable Task)

```md
## Description
Define and document a reusable GitHub issue contract for one executable task.

## Acceptance Criteria
- [ ] `templates/github-issue-task.md` exists.
- [ ] Dependency syntax rules are deterministic and parseable.
- [ ] Status label contract is documented.

## Dependencies
- none

## Layer
api

## File Hints
- templates/github-issue-task.md

## Status Labels
- status:todo
```
