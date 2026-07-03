# Prompt: Fix Bug

Use when investigating and fixing a reported bug.

```
Read AGENTS.md.
Load memory/gotchas.md.
Load memory/ documents relevant to the affected area.
Read the failing test or reproduce steps below.
Read the affected source files.

Find the root cause. Fix it.
Do not change tests to match broken behavior.
Add a test if the bug had no coverage.
Update memory/gotchas.md if this is a non-obvious pitfall.

Bug: <description or failing test output>
```
