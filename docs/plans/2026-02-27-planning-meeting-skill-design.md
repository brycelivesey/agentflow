# Planning Meeting Skill - Design Document

## User Story

As a developer using AI coding agents, I want a structured planning workflow that mirrors how high-performing engineering teams (e.g., Facebook) plan features - collaborative discussion, multiple perspectives, small stacked tasks - so that I avoid one-shot plans and giant PRs in favor of trunk-based development with small, reviewable diffs.

## Context

- Working directory: `/Users/brycelivesey/Projects/`
- Existing projects: FOMO (active, uses worktrees), FantasyFootball, PuttingMetronome, etc.
- Current workflow pain: Claude Code's planning mode feels like one-shot Gitflow, producing 1-3k line PRs
- Desired workflow: Facebook-style planning meetings producing stacked diffs
- Tools: Claude Code (primary implementation), Codex (planning), both support identical `SKILL.md` format

## Discussion Summary

- **Role dynamics:** User is the product owner and active participant. AI considers multiple perspectives (product, architecture, engineering, QA) via prompt guidance, not literal role-play.
- **Conversation style:** Natural back-and-forth, not scripted. AI should research the codebase to answer its own questions before asking the user. No limit on questions - thoroughness over speed.
- **Task sizing:** Facebook-style: one logical change per diff, reviewable in ~15 minutes, no hard line count. Layer-based stacking (data -> API -> UI -> tests).
- **Plan output:** Markdown template committed to the target project's repo at `.agentflow/plans/`.
- **Tool agnostic:** Skill file format works for both Codex (`$planning-meeting`) and Claude Code (`/planning-meeting`). Install script symlinks to both tool directories.
- **Enforcement:** Start with template structure (gaps are visually obvious). Evolve toward programmatic validation later, eventually a full plugin like superpowers.

## Approach

Build a single `SKILL.md` file that works with both Codex and Claude Code. The skill guides a collaborative planning conversation through natural phases (context gathering, clarification, approach discussion, task breakdown) and produces a structured plan artifact.

A simple install script symlinks the skill to both `~/.agents/skills/` and `~/.claude/skills/` for global availability.

### Alternatives Considered

1. **Prompt template + manual copy-paste:** Too much friction per use. The skill system handles invocation natively.
2. **CLI script wrapper:** Premature - adds build/maintenance overhead before we know where friction exists.
3. **Claude Code only (plugin):** Locks out Codex. The converged SKILL.md format means we get both tools for free.

## Project Structure

```
agentflow/
  skills/
    planning-meeting/
      SKILL.md
  templates/
    plan-output.md
  install.sh
  docs/
    plans/
  README.md
```

## Skill Behavior

The planning-meeting skill instructs the AI to:

1. **Listen** - User describes the feature or user story
2. **Research** - Explore the relevant parts of the codebase to understand existing patterns, architecture, and constraints. Answer its own questions from the code before asking the user.
3. **Clarify** - Ask the user questions it couldn't answer from the code. Consider perspectives: product (who/what/why), architecture (system fit, component impact), engineering (complexity, risk), QA (verification, edge cases). No scripted questions - let the AI determine what to ask based on context.
4. **Discuss approach** - Share recommendation and alternatives. Go back and forth until an approach is agreed. No fixed number of options.
5. **Break into tasks** - Decompose into stacked tasks following Facebook-style principles:
   - One logical change per task (one idea, one diff)
   - Reviewable in ~15 minutes
   - Clear acceptance criteria
   - Defined dependencies and ordering
   - Layer-based when appropriate (data -> API -> UI -> tests)
6. **Output plan** - Write the plan using the template, commit to target project at `.agentflow/plans/YYYY-MM-DD-<feature-name>.md`

## Plan Output Template

```markdown
# [Feature Name]

## User Story
[What the user wants, in their words]

## Context
[What was learned from exploring the codebase]

## Discussion Summary
[Key decisions, questions raised and answered, concerns addressed]

## Approach
[The agreed technical approach and why]

### Alternatives Considered
[Other approaches and why they weren't chosen]

## Tasks

### Task 1: [Name]
- **Description:** What this task accomplishes
- **Acceptance Criteria:** How we know it's done
- **Dependencies:** What must land before this
- **Files likely affected:** [list]
- **Layer:** data / api / ui / test / infra

## Open Questions
[Anything unresolved for implementation]
```

## Future Phases (Not in scope)

- **Phase 2:** Coding agent skill - takes a task from the plan, implements it using agent teams (programmer, reviewer, tester, report writer)
- **Phase 3:** PR review workflow - assigns PR to human + AI reviewers, structured merge/revise/reject decisions
- **Phase 4:** Programmatic enforcement - schema validation, checklist gates, plugin-style enforcement like superpowers
