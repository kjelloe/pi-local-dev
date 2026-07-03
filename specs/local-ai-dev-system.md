# Spec: Local AI Development System

Source: Local_AI_Development_System_June_2026.md (reference doc, preserved at repo root)

## Goal

A long-lived repository where both humans and local AI agents can understand and extend the
codebase over time. Important knowledge accumulates in the repo — not in conversation history.

## Stack

| Role | Tool |
|---|---|
| Model server | llama-server (llama.cpp, CUDA) |
| Primary coding CLI | Pi (`@earendil-works/pi-coding-agent`) |
| Browser testing | Playwright |
| Test framework | node:test (JS) / pytest (Python) |
| Version control | Git |
| Containers | Docker (as needed) |
| MCP servers | filesystem, Git, SQLite, browser (as needed) |

## Principles

1. Keep the stack intentionally simple.
2. Store project knowledge in the repository, not only in conversations.
3. Prefer small, testable changes.
4. Treat documentation as executable context.
5. Continuously extract knowledge from development into durable documentation.

## Agent Workflow

1. Understand the request.
2. Read AGENTS.md.
3. Load only relevant memory/ documents.
4. Load only relevant patterns/.
5. Read the affected source files.
6. Read existing tests.
7. Produce a short implementation plan.
8. Implement small changes.
9. Run tests.
10. Run Playwright when UI behavior changes.
11. Update documentation if required.
12. Commit.

## Repository Maintenance (run periodically)

- Extract new knowledge into memory/.
- Add or refine implementation patterns.
- Improve reusable prompts.
- Remove obsolete documentation.
- Review architecture drift.
- Review TODOs.
- Keep AGENTS.md concise (target: 100–200 lines).

## Hardware Targets

| VRAM | Class |
|---|---|
| 8 GB | 7B–8B models |
| 16 GB | 14B class |
| 24 GB | 20B–32B quantized |
| 2×24 GB | 30B–80B MoE, large coding models |

This system: RTX 4090 (24 GB) + RTX 3090 (24 GB) = 48 GB total.
