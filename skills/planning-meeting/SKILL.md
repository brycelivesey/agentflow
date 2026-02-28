---
name: planning-meeting
description: Use when starting feature work, planning a new feature, or beginning a user story. This skill runs a collaborative planning conversation and outputs small, stacked GitHub Issues only (no markdown plan files). Triggers on phrases like "plan a feature", "planning meeting", "let's plan", "new feature", "user story", and "break this into tasks".
---

# Planning Meeting

## Overview

Conduct a collaborative planning meeting that produces executable GitHub Issues for trunk-based development.

Operational rules:
- Output GitHub Issues only.
- Do not write `.agentflow/plans/` markdown plan files.
- Use `templates/github-issue-task.md` as the canonical issue-body contract.
- Stop immediately if GitHub operations or schema checks fail.

## Process

### Phase 1: Listen

Understand the user story and desired outcome before proposing implementation details.

### Phase 2: Research

Before asking questions, inspect the repository:

- Read relevant code, configs, and architecture.
- Identify existing patterns and conventions to follow.
- Check recent commits and related issues/PRs.
- Identify likely files/components touched.
- Build an initial view of risks, constraints, and dependencies.

Ask the user only what cannot be learned from the codebase.

### Phase 3: Clarify

Ask targeted questions as needed across:
- Product outcomes
- Architectural fit
- Implementation risk/complexity
- Verification strategy

### Phase 4: Discuss Approach

Recommend an approach, explain tradeoffs, and discuss alternatives until the user agrees on a direction.

### Phase 5: Decompose into Tasks

Break the work into stacked tasks:

- One logical change per task.
- Small enough to review quickly.
- Explicit acceptance criteria.
- Explicit dependencies.
- Layer tag per task: `data|api|ui|test|infra`.

### Phase 6: Create GitHub Issues (Required)

Create issues in dependency order.

#### 6.1 Preflight (required)

Run and require success:

```bash
gh auth status
gh repo view --json nameWithOwner
```

If either command fails, stop and report the error.

#### 6.2 Issue body contract (required)

Every issue body must include these sections:

1. `## Description`
2. `## Acceptance Criteria`
3. `## Dependencies`
4. `## Layer`
5. `## File Hints`
6. `## Status Labels`

Validation rules:
- `## Layer` value is exactly one of `data|api|ui|test|infra`.
- `## Dependencies` entries are only `- none` or `- #<issue_number>`.
- If `- none` is present, it is the only dependency entry.
- Dependency references are unique.
- `## Status Labels` has exactly one entry and it is one of:
  - `- status:todo`
  - `- status:in-progress`
  - `- status:done`
- For newly created issues in planning, initialize with `- status:todo`.

Recommended executable validation before create/edit:

```bash
TASK_BODY_FILE="<path-to-generated-body>"

for header in \
  "## Description" \
  "## Acceptance Criteria" \
  "## Dependencies" \
  "## Layer" \
  "## File Hints" \
  "## Status Labels"; do
  rg -q "^${header}$" "$TASK_BODY_FILE" || {
    echo "Schema error: missing ${header}"
    exit 1
  }
done

LAYER_VALUE="$(awk '/^## Layer$/{getline; print; exit}' "$TASK_BODY_FILE")"
case "$LAYER_VALUE" in
  data|api|ui|test|infra) ;;
  *) echo "Schema error: invalid layer '$LAYER_VALUE'"; exit 1 ;;
esac

awk '
  BEGIN { count=0; none_count=0; ok=1; dup=0 }
  /^## Dependencies$/ { in_deps=1; next }
  /^## / { in_deps=0 }
  in_deps {
    if ($0 ~ /^[[:space:]]*$/) next
    if ($0 !~ /^- /) { ok=0; next }
    count++
    if ($0 == "- none") { none_count++; next }
    if ($0 ~ /^- #[1-9][0-9]*$/) {
      dep=substr($0,4)
      if (seen[dep]++) dup=1
      next
    }
    ok=0
  }
  END { if (count==0 || ok==0 || dup==1 || (none_count>0 && count!=1)) exit 1 }
' "$TASK_BODY_FILE" || {
  echo "Schema error: invalid dependencies block"
  exit 1
}

STATUS_COUNT="$(awk '/^## Status Labels$/{f=1;next}/^## /{f=0}f' "$TASK_BODY_FILE" | rg -c '^- ')"
if [ "$STATUS_COUNT" -ne 1 ] || ! awk '/^## Status Labels$/{f=1;next}/^## /{f=0}f' "$TASK_BODY_FILE" | rg -q '^- status:(todo|in-progress|done)$'; then
  echo "Schema error: invalid status labels block"
  exit 1
fi
```

#### 6.3 Create/update issue commands (required)

Create:

```bash
ISSUE_URL="$(gh issue create \
  --title "$TASK_TITLE" \
  --body-file "$TASK_BODY_FILE" \
  --label "status:todo")" || {
  echo "Issue creation failed for '$TASK_TITLE'"
  exit 1
}
```

Edit:

```bash
gh issue edit "$ISSUE_NUMBER" --body-file "$TASK_BODY_FILE" || {
  echo "Issue update failed for #$ISSUE_NUMBER"
  exit 1
}
```

#### 6.4 Return result to user

Return created issues in dependency order:
- `Task N -> #<issue_number> <issue_url>`

## Failure Policy

Fail fast on any of:
- Preflight failure (`gh auth status`, `gh repo view`)
- Schema validation failure
- `gh issue create` failure
- `gh issue edit` failure

When failing, report:
- Failed command
- Error category (`auth|network|permissions|schema|other`)
- Suggested corrective action

## Key Principles

- Research first, ask second.
- Keep conversation natural, not form-driven.
- Keep tasks small and coherent.
- Keep dependencies explicit.
- Use GitHub Issues as the single planning output.
