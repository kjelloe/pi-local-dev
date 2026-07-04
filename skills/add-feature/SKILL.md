---
name: add-feature
description: Implement a new feature from a description or spec. Loads project context, plans, implements, tests, and updates docs.
---

# Skill: Add Feature

## Steps

1. Read `AGENTS.md` for coding rules and architecture overview.
2. If a spec exists in `specs/`, read it.
3. Load `memory/` documents relevant to the affected area.
4. Read the affected source files.
5. Read existing tests for the affected area.
6. State a short implementation plan (≤8 bullet points). Proceed immediately unless the plan is genuinely uncertain.
7. Implement in small, testable chunks.
8. Add a test for any non-trivial logic.
9. Run the test suite: `npm test` or `pytest tests/`.
10. If UI behavior changed, run `npx playwright test`.
11. Update `memory/` or `patterns/` if you discovered something worth preserving.
12. Commit when the user confirms it's ready.

## Constraints

- Scope = exactly what was asked. No extra features or abstractions.
- No comments explaining what the code does — only WHY if non-obvious.
- No defensive error handling for things that cannot happen.
