---
name: planning-meeting
description: Use when starting feature work, planning a new feature, or beginning a user story. This skill guides a collaborative planning conversation that produces small, stacked tasks for trunk-based development. Triggers on phrases like "plan a feature", "planning meeting", "let's plan", "new feature", "user story", "break this into tasks".
---

# Planning Meeting

## Overview

Conduct a collaborative planning meeting to break a feature into small, stacked tasks suitable for trunk-based development. Inspired by Facebook's engineering culture: small diffs, one idea per change, reviewable in ~15 minutes.

## Process

### Phase 1: Listen

The user describes the feature or user story they want to build. Listen and understand before doing anything else.

### Phase 2: Research

Before asking the user any questions, explore the codebase thoroughly:

- Read relevant source files, configs, and existing architecture
- Check for existing patterns, conventions, and prior implementations of similar features
- Look at recent commits and any existing plans in `.agentflow/plans/`
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

### Phase 6: Output Plan

Write the plan using the template below. Present it to the user for review. After approval, write it to the target project at:

```
<project-root>/.agentflow/plans/YYYY-MM-DD-<feature-name>.md
```

Create the `.agentflow/plans/` directory if it doesn't exist.
Keep plans as local working artifacts by default (typically gitignored).
Only commit a plan file when the user explicitly asks to version it.

## Plan Output Template

Use this structure for the final plan document:

```
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

### Task 1: [Name]
- **Description:** What this task accomplishes
- **Acceptance Criteria:** How we know it's done
- **Dependencies:** What must land before this
- **Files likely affected:** [list]
- **Layer:** data / api / ui / test / infra

### Task 2: [Name]
...
(continue for all tasks)

## Open Questions
[Anything unresolved that might come up during implementation]
```

## GitHub Issue Creation

After the plan is approved, create one GitHub Issue per task using the template at `templates/github-issue-task.md`. Each issue body must include these required sections:

- `## Description`
- `## Acceptance Criteria`
- `## Dependencies`
- `## Layer`
- `## File Hints`
- `## Status Labels`

### Schema Validation

After creating each issue, validate its body against the schema. The following snippet can be piped the raw issue body (e.g., from `gh issue view <N> --json body -q .body`):

```bash
awk '
  /^## Description/        { has_desc = 1 }
  /^## Acceptance Criteria/ { has_ac = 1 }
  /^## File Hints/          { has_fh = 1 }

  /^## Layer/        { in_layer = 1; next }
  in_layer && /^## / { in_layer = 0 }
  in_layer && /^[[:space:]]*$/ { next }
  in_layer && /^data[[:space:]]*$/  { has_layer = 1; in_layer = 0 }
  in_layer && /^api[[:space:]]*$/   { has_layer = 1; in_layer = 0 }
  in_layer && /^ui[[:space:]]*$/    { has_layer = 1; in_layer = 0 }
  in_layer && /^test[[:space:]]*$/  { has_layer = 1; in_layer = 0 }
  in_layer && /^infra[[:space:]]*$/ { has_layer = 1; in_layer = 0 }

  /^## Dependencies/        { in_deps = 1; next }
  in_deps && /^## /         { in_deps = 0 }
  in_deps && /^[[:space:]]*$/ { next }
  in_deps && /^- none[[:space:]]*$/    { has_deps = 1 }
  in_deps && /^- #[0-9]+[[:space:]]*$/ { has_deps = 1 }

  /^## Status Labels/        { in_status = 1; status_count = 0; next }
  in_status && /^## /        { in_status = 0 }
  in_status && /^[[:space:]]*$/ { next }
  in_status && /^- status:todo[[:space:]]*$/        { status_count++; has_status = 1 }
  in_status && /^- status:in-progress[[:space:]]*$/ { status_count++; has_status = 1 }
  in_status && /^- status:done[[:space:]]*$/        { status_count++; has_status = 1 }

  END {
    ok = 1
    if (has_desc == 0)   { print "FAIL: missing ## Description";            ok = 0 }
    if (has_ac == 0)     { print "FAIL: missing ## Acceptance Criteria";     ok = 0 }
    if (has_fh == 0)     { print "FAIL: missing ## File Hints";              ok = 0 }
    if (has_layer == 0)  { print "FAIL: missing or invalid ## Layer";        ok = 0 }
    if (has_deps == 0)   { print "FAIL: missing or invalid ## Dependencies"; ok = 0 }
    if (has_status == 0) { print "FAIL: missing ## Status Labels";           ok = 0 }
    if (status_count > 1) { print "FAIL: multiple status labels";            ok = 0 }
    if (ok) print "PASS"
    exit (ok == 0)
  }
'
```

**Whitespace handling:** The snippet skips blank lines between section headers and their values, so normal markdown spacing (e.g., a blank line after `## Layer`) does not cause false failures.

## Key Principles

- Research first, ask second. Explore the codebase before asking the user questions.
- No scripted questions. Let context determine what to ask.
- Natural conversation. This is a collaborative discussion, not a form to fill out.
- One idea per diff. Every task should be a single, coherent change.
- Trunk-based development. Small changes that land on main frequently.
- Plans live in `.agentflow/plans/` as working state unless the user requests versioning.
