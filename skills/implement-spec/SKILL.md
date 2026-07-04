---
name: implement-spec
description: Build out a full specification from specs/. Loads all relevant context, produces a plan, implements in small commits, and keeps docs current.
---

# Skill: Implement Spec

## Steps

1. Read `AGENTS.md`.
2. Read the target spec from `specs/` in full.
3. Load **all** memory/ documents — this is a larger task.
4. Load relevant `patterns/`.
5. Read existing source and tests.
6. Produce a short implementation plan (≤10 bullet points). **Wait for user approval before writing any code.**
7. Implement in small commits — one logical change per commit.
8. Write tests alongside implementation.
9. Update `ARCHITECTURE.md` if structure changes.
10. Extract any discovered knowledge into `memory/`.
11. Run the full test suite after each logical chunk.

## Constraints

- Plan first, code second.
- Each commit should be independently meaningful.
- No scope beyond the spec.
