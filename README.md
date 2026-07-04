# localdev

Local AI development system. Model server: llama-server. Coding CLI: Pi.
All project knowledge lives in this repo.

## Quick Start

```bash
# One command — starts llama-server if not running, then launches Pi
localai

# Or from the repo
./scripts/dev.sh
```

Pi auto-loads `AGENTS.md` from this directory. All tools are available immediately:
`bash`, `read`, `edit`, `write`, `grep`, `find`, `ls`.

## Skills (slash commands inside Pi)

| Command | Purpose |
|---|---|
| `/skill:add-feature` | Load context → plan → implement → test → update docs |
| `/skill:fix-bug` | Find root cause → fix → add test → update gotchas |
| `/skill:review` | Correctness, scope, security review — no style nits |
| `/skill:implement-spec` | Plan (wait for approval) → small commits → extract knowledge |
| `/skill:maintain` | Periodic cleanup: extract knowledge, prune stale docs, review TODOs |

## Alternate Models

```bash
# Qwen3-Coder 1M context (perfect coding score)
MODEL=Qwen3-Coder-30B-A3B-Instruct-1M-Q4_K_M.gguf CTX=131072 ./scripts/start-llama.sh

# Qwen3.5-35B thinking model (fastest at 153 tok/s)
MODEL=Qwen_Qwen3.5-35B-A3B-Q4_K_M.gguf ./scripts/start-llama.sh

# Single-GPU (4090 only — faster for small MoE models that fit in 24 GB)
CUDA_VISIBLE_DEVICES=0 ./scripts/start-llama.sh
```

## Tests

```bash
bash tests/test-server-health.sh   # server smoke test
npm test                           # node:test suite
pytest tests/                      # Python suite
npx playwright test                # browser tests
```

## Layout

```
AGENTS.md          agent entry point — read this first
ARCHITECTURE.md    stack, Pi tools, model benchmarks, hardware
memory/            long-lived knowledge: models, decisions, gotchas
patterns/          implementation recipes
skills/            Pi slash-command workflows (/skill:name)
prompts/           human-readable versions of the same workflows
specs/             feature specifications
tests/             unit, integration, and smoke tests
scripts/           dev.sh (launcher), start-llama.sh (server only)
src/               application source
public/            static assets
.pi/settings.json  Pi project config: default model, skills path
```

See `AGENTS.md` for coding rules and context loading order.
See `ARCHITECTURE.md` for full stack reference and model table.
See `memory/models.md` to switch or compare models.
