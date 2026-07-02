# AGENTS.md

## Project Overview

Local AI development repository. Stack: llama-server (local model) + Pi (coding CLI).
All project knowledge lives here — not in conversations.

## Commands

```bash
# Start the model server (port 8080, noctrex-qwen3.6:35b by default)
./scripts/start-llama.sh

# Override model or context
MODEL=Qwen3-Coder-30B-A3B-Instruct-1M-Q4_K_M.gguf CTX=131072 ./scripts/start-llama.sh

# Run Pi against local server
pi --model llama-local/local

# Run tests
npm test          # node:test
pytest tests/     # Python

# Run Playwright
npx playwright test
```

## Architecture

See ARCHITECTURE.md and memory/ for details.

## Coding Rules

- Small functions, clear names, type hints where helpful.
- Stdlib-first; justify added dependencies.
- No comments unless the WHY is non-obvious.
- No defensive error handling for things that cannot happen.
- No unrequested features or abstractions.

## Context Loading Order

1. AGENTS.md (this file)
2. Relevant memory/ documents
3. Relevant patterns/
4. Relevant specs/
5. Affected source files
6. Relevant tests

Load only what is relevant to the current task.

## Where to Find Things

- `memory/`    — architecture, domain model, API, DB, design decisions, known gotchas
- `patterns/`  — implementation recipes (new endpoint, migration, Playwright test, etc.)
- `prompts/`   — reusable agent workflows (add feature, fix bug, review, release)
- `specs/`     — feature specifications
- `tests/`     — unit/integration tests
- `src/`       — application source
- `scripts/`   — operational scripts (model server, CI helpers)
