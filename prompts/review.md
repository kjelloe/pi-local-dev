# Prompt: Code Review

Use for reviewing a diff or PR before merging.

```
Read AGENTS.md for coding rules.

Review the diff below for:
- Correctness bugs (logic errors, off-by-ones, missed edge cases)
- Scope creep (changes beyond what the task required)
- Missing tests for non-trivial logic
- Violations of the coding rules in AGENTS.md

Do not flag style preferences. Only flag things that are wrong or risky.
For each finding: file, line, problem, suggested fix.

Diff:
<paste diff or describe changes>
```
