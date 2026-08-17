# AGENTS.md

## Project Overview

Local AI development repository. Stack: llama-server (local model) + Pi (coding CLI).
All project knowledge lives here — not in conversations.

This repo also doubles as a launcher: `localai` starts the server (if needed) and launches Pi
against whatever directory you're currently in, with this repo's skills and the local model
available regardless of project — run it from `~/GIT/some-other-project` to work on that project
directly, not just from inside `localdev`.

## Commands

```bash
# Start server + Pi in one command (alias from anywhere) — operates on the CURRENT directory,
# so `cd ~/GIT/some-project && localai` works on that project, not localdev
localai

# Or from the repo directly
./scripts/dev.sh

# Override model or context (server only)
MODEL=Qwen3-Coder-30B-A3B-Instruct-1M-Q4_K_M.gguf CTX=131072 ./scripts/start-llama.sh

# Release the server (frees VRAM) — server otherwise stays warm between sessions
localai-stop

# Watch GPU temps live (hwmonitor.py auto-pauses the server on thermal CRIT, auto-resumes on recovery)
localai-temps

# Hard/L6-style tasks (e.g. node_paratrooper): always restarts to the confirmed-capable config
# (qwen3.8:27b, single GPU, large ctx, bounded reasoning) instead of reusing the default coder model
localai-reasoning

# Pi skills (invoke inside Pi session)
/skill:add-feature      # implement a feature
/skill:fix-bug          # debug and fix
/skill:review           # code review
/skill:implement-spec   # build out a spec
/skill:maintain         # periodic repo maintenance

# Run tests
npm test          # node:test
pytest tests/     # Python

# Run Playwright
npx playwright test

# Server health check
bash tests/test-server-health.sh
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

- `memory/models.md`     — available models, benchmark scores, llama-server flags
- `memory/gotchas.md`    — known issues: ctx caps, MTP, tensor_split, Pi compat flags
- `memory/decisions.md`  — design decisions and their rationale
- `patterns/start-server.md` — how to start with different models, health check, troubleshooting
- `skills/`              — Pi slash-command workflows (add-feature, fix-bug, review, implement-spec, maintain)
- `prompts/`             — human-readable versions of the same workflows
- `specs/`               — feature specifications
- `tests/`               — unit, integration, and smoke tests
- `src/`                 — application source
- `scripts/`             — operational scripts (model server, CI helpers)
