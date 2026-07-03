# localdev

Local AI development system. Model server: llama-server. Coding CLI: Pi.
All project knowledge lives in this repo.

## Quick Start

```bash
# 1. Start the model server
./scripts/start-llama.sh

# 2. Open the coding CLI
pi --model llama-local/local

# 3. Run tests
npm test          # node:test suite
pytest tests/     # Python suite
npx playwright test
```

## Alternate Models

```bash
# Qwen3-Coder 1M context (perfect coding score)
MODEL=Qwen3-Coder-30B-A3B-Instruct-1M-Q4_K_M.gguf CTX=131072 ./scripts/start-llama.sh

# Qwen3.5-35B thinking model (fastest at 153 tok/s)
MODEL=Qwen_Qwen3.5-35B-A3B-Q4_K_M.gguf ./scripts/start-llama.sh

# Single-GPU (4090 only, faster for small MoE models)
CUDA_VISIBLE_DEVICES=0 MODEL=Qwen3.6-35B-A3B-MTP-MXFP4_MOE.gguf ./scripts/start-llama.sh
```

## Layout

```
AGENTS.md          agent entry point — read this first
ARCHITECTURE.md    stack and hardware reference
memory/            long-lived knowledge (models, decisions, gotchas)
patterns/          implementation recipes
prompts/           reusable agent workflows
specs/             feature specifications
tests/             unit and integration tests
scripts/           operational scripts
src/               application source
public/            static assets
```

See `AGENTS.md` for coding rules and context loading order.
See `ARCHITECTURE.md` for model benchmarks and server config.
