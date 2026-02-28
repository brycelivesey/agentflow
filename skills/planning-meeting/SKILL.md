---
name: planning-meeting
description: Use when starting feature work, planning a new feature, or beginning a user story. This skill guides a collaborative planning conversation that produces small, stacked GitHub Issues for trunk-based development. Triggers on phrases like "plan a feature", "planning meeting", "let's plan", "new feature", "user story", "break this into tasks".
---

# Planning Meeting

## Overview

Conduct a collaborative planning meeting to break a feature into small, stacked tasks suitable for trunk-based development. Operational output is GitHub Issues only. Do not write task plans to markdown files.

This workflow is issue-only and executable:
- Every task must be created as a GitHub Issue using `gh issue create`.
- Every issue body must follow the single-task schema in `templates/github-issue-task.md`.
- If any GitHub operation or schema validation fails, stop and report the error. No fallback path exists.

## Process

### Phase 1: Listen

The user describes the feature or user story they want to build. Listen and understand before doing anything else.

### Phase 2: Research

Before asking the user any questions, explore the codebase thoroughly:

- Read relevant source files, configs, and existing architecture
- Check for existing patterns, conventions, and prior implementations of similar features
- Look at recent commits and existing related GitHub Issues/PRs
- Identify the components, modules, and files that will likely be affected
- Form your own understanding of constraints, dependencies, and risks

The goal is to answer as many of your own questions as possible from the code. Only ask the user things you genuinely cannot determine from the codebase.

### Phase 3: Clarify

Ask the user clarifying questions. Consider these perspectives, but let the context determine which questions matter:

- **Product:** Who is this for? What problem does it solve? What does success look like?
- **Architecture:** How does this fit with the existing system? What components are affected? What patterns should we follow or deviate from?
- **Engineering:** What's the complexity? What are the risky parts? What could go wrong? What are the performance implications?
- **Testing/QA:** How do we verify this works? What are the edge cases? What's the test strategy?

Ask questions naturally. There is no limit on the number of questions. Thoroughness matters more than speed. Research the codebase between questions if new information changes what you need to ask.

### Phase 4: Discuss Approach

Share your recommended technical approach and why you think it's best. Also present alternatives worth considering. This is a back-and-forth conversation:

- Explain trade-offs honestly
- Be open to the user's preferences and domain knowledge
- Go back and forth until you both agree on an approach
- Don't force a fixed number of options - present what's relevant

### Phase 5: Break Into Tasks

Decompose the agreed approach into stacked tasks following these principles:

- **One logical change per task** - each task is one idea, one diff
- **Reviewable in ~15 minutes** - a reviewer should be able to understand the full context quickly
- **Clear acceptance criteria** - how do we know the task is done?
- **Defined dependencies** - what must land before this task can start?
- **Layer-based when appropriate** - consider stacking: data model -> API -> UI -> tests
- **No hard line count** - size by cohesion, not by counting lines

### Phase 6: Create GitHub Issues (Required)

Convert each planned task into one executable GitHub Issue. GitHub Issues are the canonical task tracker and the only operational output.

#### 6.1 Preflight checks (required)

Run and require success:

```bash
gh auth status
gh repo view --json nameWithOwner
```

If either command fails (auth, network, permissions, repo context), stop and report the error.

#### 6.2 Enforce task schema (required)

For every task issue body, use the exact section structure from:

- `templates/github-issue-task.md`

Required sections (canonical order shown):

1. `## Description`
2. `## Acceptance Criteria`
3. `## Dependencies`
4. `## Layer`
5. `## File Hints`
6. `## Status Labels`

Validation rules:

- `## Dependencies` entries must be exactly `- none` or `- #<issue_number>` per `templates/github-issue-task.md`.
- `## Layer` must be exactly one of `data|api|ui|test|infra`.
- `## Status Labels` must contain exactly one of `- status:todo`, `- status:in-progress`, or `- status:done`.
- For newly created issues in this phase, initialize `## Status Labels` as `- status:todo`.
- One issue body represents exactly one executable task.

Executable validation pattern (required before any create/edit call):

```bash
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
  *)
    echo "Schema error: invalid layer '${LAYER_VALUE}'"
    exit 1
    ;;
esac

awk '
  BEGIN { entry_count=0; none_count=0; valid=1; duplicate=0; invalid_line=0 }
  /^## Dependencies$/ { in_deps=1; next }
  /^## / { in_deps=0 }
  in_deps {
    if ($0 ~ /^[[:space:]]*$/) {
      next
    }
    if ($0 !~ /^- /) {
      invalid_line=1
      next
    }
    entry_count++
    if ($0 == "- none") {
      none_count++
      next
    }
    if ($0 ~ /^- #[1-9][0-9]*$/) {
      dep_issue = substr($0, 4)
      if (seen[dep_issue]++) {
        duplicate=1
      }
      next
    }
    valid=0
  }
  END {
    if (entry_count == 0 || invalid_line == 1 || valid == 0 || duplicate == 1 || (none_count > 0 && entry_count != 1)) {
      exit 1
    }
  }
' "$TASK_BODY_FILE" || {
    echo "Schema error: dependencies must be unique bullet entries of '- none' or '- #<issue_number>' and '- none' must be exclusive"
    exit 1
  }

STATUS_COUNT="$(awk '/^## Status Labels$/{flag=1;next}/^## /{flag=0}flag' "$TASK_BODY_FILE" | rg -c '^- ')"
if [ "$STATUS_COUNT" -ne 1 ] || ! awk '/^## Status Labels$/{flag=1;next}/^## /{flag=0}flag' "$TASK_BODY_FILE" | rg -q '^- status:(todo|in-progress|done)$'; then
  echo "Schema error: status labels block must contain exactly one entry with a single allowed value: '- status:todo', '- status:in-progress', or '- status:done'"
  exit 1
fi
```

If schema validation fails, stop and report the error. Do not create or update issues until schema is valid.

#### 6.3 Create issues with executable commands

Create issues in dependency order so dependency references can use already-created issue numbers.

Reusable command pattern (required):

```bash
TASK_TITLE="Task N: <short task title>"
TASK_BODY_FILE="$(mktemp)"

cat > "$TASK_BODY_FILE" <<'EOF'
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

## Status Labels
- status:todo
EOF

ISSUE_URL="$(gh issue create \
  --title "$TASK_TITLE" \
  --body-file "$TASK_BODY_FILE" \
  --label "status:todo")" || {
  echo "Issue creation failed for '${TASK_TITLE}'"
  exit 1
}
ISSUE_NUMBER="${ISSUE_URL##*/}"
echo "Created $ISSUE_URL"
```

For tasks with dependencies, replace `- none` with one line per dependency:

```md
## Dependencies
- #123
- #124
```

If a task must be updated after creation (for example, correcting dependency references), use:

```bash
ISSUE_NUMBER_TO_EDIT="<issue_number>"
gh issue edit "$ISSUE_NUMBER_TO_EDIT" --body-file "$TASK_BODY_FILE" || {
  echo "Issue update failed for #${ISSUE_NUMBER_TO_EDIT}"
  exit 1
}
```

Every `gh issue create` and `gh issue edit` command must succeed. On any failure, stop immediately and report the exact command and error.

#### 6.4 Confirm output to user

Return the created issue list in dependency order:

- `Task N -> #<issue_number> <issue_url>`

Do not write `.agentflow/plans/` files. Do not provide markdown-plan fallback output.

## Issue Body Contract

Use `templates/github-issue-task.md` as the canonical body contract for each task issue.

## Failure Policy (No Fallback)

Stop immediately and report failure when any of the following occurs:

- `gh auth status` fails
- `gh repo view` fails
- `gh issue create` fails
- `gh issue edit` fails
- Issue body fails schema validation from `templates/github-issue-task.md`
- Required status label application fails

Failure report must include:

- The command that failed
- The error category (auth/network/permissions/schema/other)
- Suggested corrective action

No markdown-plan fallback is allowed.

## Key Principles

- Research first, ask second. Explore the codebase before asking the user questions.
- No scripted questions. Let context determine what to ask.
- Natural conversation. This is a collaborative discussion, not a form to fill out.
- One idea per diff. Every task should be a single, coherent change.
- Trunk-based development. Small changes that land on main frequently.
- GitHub Issues are the only task-tracking output for planning.
