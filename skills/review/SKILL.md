---
name: review
description: Review a diff or set of changes for correctness bugs, scope creep, missing tests, and coding rule violations. Does not flag style preferences.
---

# Skill: Code Review

## Steps

1. Read `AGENTS.md` for the coding rules that apply.
2. Review the diff or files specified.

## What to check

- **Correctness**: logic errors, off-by-ones, missed edge cases, wrong types
- **Scope**: changes beyond what the task required
- **Tests**: non-trivial logic without a test
- **Rules**: violations of AGENTS.md coding rules (no comments explaining what, no unused abstractions, no impossible-case guards)
- **Security**: command injection, SQL injection, XSS, unsafe deserialization, exposed secrets

## Output format

For each finding: `file:line — problem — suggested fix`

Only report things that are wrong or risky. Do not flag style preferences or neutral choices.
If there are no findings, say so explicitly.
