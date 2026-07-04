# Spec: Local AI Development System

Source: Local_AI_Development_System_June_2026.md (reference doc, preserved at repo root)

## Goal

A long-lived repository where both humans and local AI agents can understand and extend the
codebase over time. Important knowledge accumulates in the repo — not in conversation history.

## Stack

| Role | Tool | Notes |
|---|---|---|
| Model server | llama-server (llama.cpp, CUDA) | OpenAI-compatible API, port 8080 |
| Coding CLI | Pi (`@earendil-works/pi-coding-agent`) | bash/read/edit/write/grep/find/ls tools |
| Browser testing | Playwright | |
| Test framework | node:test (JS) / pytest (Python) | |
| Version control | Git | |
| Containers | Docker | as needed |
| MCP servers | filesystem, Git, SQLite, browser | as needed via Pi extensions |

## Principles

1. Keep the stack intentionally simple.
2. Store project knowledge in the repository, not only in conversations.
3. Prefer small, testable changes.
4. Treat documentation as executable context.
5. Continuously extract knowledge from development into durable documentation.

## Launch Pattern

A single command starts the full system:

```bash
localai           # alias: cd ~/GIT/localdev && ./scripts/dev.sh
```

`dev.sh` checks whether llama-server is already healthy, starts it if not, waits for readiness,
then execs Pi. Pi inherits cwd and auto-loads `AGENTS.md`.

## Pi Tool Set

Pi provides these built-in tools to the local model:
`bash`, `read`, `edit`, `write`, `grep`, `find`, `ls`

This matches the Claude Code tool surface, making skills and workflows portable between
local (Pi + llama-server) and cloud (Claude Code) agents.

## Skills (Slash Commands)

Reusable workflows are implemented as Agent Skills (`agentskills.io` standard).
Each skill lives in `skills/<name>/SKILL.md` with YAML frontmatter (`name`, `description`).

Pi includes them in the system prompt and loads the file via `read` when the task matches.
Explicit invocation: `/skill:name` inside a Pi session.

Current skills:
- `add-feature` — context → plan → implement → test → update docs
- `fix-bug` — root cause → fix → test → update gotchas
- `review` — correctness, scope, security; no style nits
- `implement-spec` — plan (wait for approval) → small commits → extract knowledge
- `maintain` — extract knowledge, prune stale docs, review TODOs, check architecture drift

## Agent Workflow

1. Understand the request.
2. Read AGENTS.md.
3. Load only relevant memory/ documents.
4. Load only relevant patterns/ or skills/.
5. Read the affected source files.
6. Read existing tests.
7. Produce a short implementation plan.
8. Implement small changes.
9. Run tests.
10. Run Playwright when UI behavior changes.
11. Update documentation if required.
12. Commit.

## Context Loading (Pi)

Pi walks from cwd up to `/` loading every `AGENTS.md` (or `CLAUDE.md`) it finds,
plus `~/.pi/agent/AGENTS.md` for global rules. Project-level `.pi/settings.json`
sets the default provider and model so no `--model` flag is needed.

## Repository Maintenance (run `/skill:maintain` periodically)

- Extract new knowledge into memory/.
- Add or refine patterns/.
- Improve skills/.
- Remove obsolete documentation.
- Review architecture drift vs ARCHITECTURE.md.
- Review TODOs.
- Keep AGENTS.md concise (target: ≤200 lines).

## Hardware Targets

| VRAM | Class |
|---|---|
| 8 GB | 7B–8B models |
| 16 GB | 14B class |
| 24 GB | 20B–32B quantized |
| 2×24 GB | 30B–80B MoE, large coding models |

This system: RTX 4090 (24 GB) + RTX 3090 (24 GB) = 48 GB total.
