# ADR: README Structure and Content Scope

## Status
Accepted

## Context
The agentflow repo had no README or external-facing documentation. First-time OSS users had no way to understand what the project does, how to install it, or how to use its skills. The plan called for a minimal, external-user-first README covering project purpose, prerequisites, install, usage, and included skills.

## Decision
Followed existing repo patterns with no new architectural decisions. The README mirrors the structure defined by `install.sh` (two install targets, two skills) and uses the skill names as slash commands matching the `name:` frontmatter in each SKILL.md. Used a `<repo-url>` placeholder for the clone URL since the canonical remote URL may vary. Included a project structure section to orient new users quickly.

## Alternatives Considered
- Including detailed skill documentation in the README (rejected): the SKILL.md files serve as canonical references; duplicating content creates drift risk.
- Generating the README from source files (rejected): premature for the current repo size and adds tooling complexity.

## Consequences
External users can now understand, install, and use agentflow from the README alone. The README will need updates when skills are added or `install.sh` behavior changes — this is addressed by Task 4 in the plan (manual maintenance rule).
