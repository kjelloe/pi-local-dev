---
name: fix-bug
description: Investigate and fix a bug. Finds root cause, fixes it, adds a test if coverage was missing, and updates gotchas if the issue is non-obvious.
---

# Skill: Fix Bug

## Steps

1. Read `AGENTS.md`.
2. Read `memory/gotchas.md` — the bug may be a known pattern.
3. Load `memory/` documents relevant to the affected area.
4. Read the failing test output or reproduce steps provided.
5. Read the affected source files.
6. Find the root cause. State it in one line before writing any fix.
7. Fix it. Do not change tests to match broken behavior.
8. Add a test if the bug had no coverage.
9. Run the full test suite: `npm test` or `pytest tests/`.
10. If the bug was non-obvious, add an entry to `memory/gotchas.md`.
11. Commit.

## Constraints

- Fix the root cause, not the symptom.
- No behaviour changes beyond the bug scope.
