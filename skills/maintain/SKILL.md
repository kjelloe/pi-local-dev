---
name: maintain
description: Periodic repository maintenance: extract knowledge into memory/, refine patterns, prune stale docs, review TODOs, and keep AGENTS.md concise.
---

# Skill: Repository Maintenance

Run this periodically to keep the knowledge base healthy.

## Steps

1. Read `AGENTS.md`, `ARCHITECTURE.md`, and all `memory/` docs.
2. Scan recent git log for anything worth extracting: `git log --oneline -30`
3. **Extract knowledge**: any non-obvious finding from recent work → `memory/gotchas.md` or `memory/decisions.md`.
4. **Refine patterns**: if a pattern in `patterns/` is incomplete or wrong, update it.
5. **Prune stale docs**: remove memory entries that no longer apply.
6. **Review TODOs**: `grep -rn "TODO\|FIXME\|HACK" src/ tests/` — file issues or fix trivial ones.
7. **Architecture drift**: check if `ARCHITECTURE.md` still matches the actual stack.
8. **AGENTS.md length**: if it exceeds ~200 lines, trim — move detail to memory/.
9. Commit with message: `docs: periodic maintenance YYYY-MM-DD`.

## Constraints

- Do not add memory for things derivable from the code.
- Do not pad memory with content-free entries.
- Keep AGENTS.md as the concise entry point — depth lives in memory/.
