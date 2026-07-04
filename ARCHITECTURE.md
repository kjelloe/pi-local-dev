# Architecture

## Launch

```bash
localai              # alias: cd ~/GIT/localdev && ./scripts/dev.sh
./scripts/dev.sh     # starts llama-server if not running, then launches Pi
```

`dev.sh` polls `/health` for up to 90 s, then execs `pi` with inherited env.
Log while server starts: `/tmp/llama-server.log`

## Model Server

- Binary: `~/.local/bin/llama-server` → `~/GIT/llama.cpp/build/bin/llama-server` (CUDA, Ampere+)
- Default model: `Qwen3.6-35B-A3B-MTP-MXFP4_MOE.gguf` (noctrex-qwen3.6:35b)
- Models dir: `~/GIT/llm-test-bench/allmodels/` (`$LLAMA_MODELS_DIR`)
- API: OpenAI-compatible at `http://127.0.0.1:8080/v1`
- GPU: RTX 4090 (dev 0) + RTX 3090 (dev 1), `tensor_split=1,1`, no NVLink

Override with env vars before calling `start-llama.sh`:
```bash
MODEL=<filename>   # GGUF file relative to LLAMA_MODELS_DIR
CTX=<tokens>       # context window (default: 65536)
PORT=<port>        # (default: 8080)
```

## Coding CLI (Pi)

- Package: `@earendil-works/pi-coding-agent` v0.80.3
- Binary: `~/.local/share/npm-global/bin/pi`
- Global provider config: `~/.pi/agent/models.json` → provider `llama-local`, port 8080
- Project config: `.pi/settings.json` → `defaultProvider: llama-local`, `defaultModel: local`
  Running `pi` inside this repo needs no `--model` flag.

### Built-in tools

| Tool | Does |
|---|---|
| `bash` | Run shell commands |
| `read` | Read a file |
| `edit` | Apply targeted edits to a file |
| `write` | Write a new file |
| `grep` | Search file contents |
| `find` | Find files by name/pattern |
| `ls` | List directory contents |

### Skills (slash commands)

Skills live in `skills/` — each is a subdirectory with `SKILL.md`.
Registered via `.pi/settings.json`: `"skills": ["./skills"]`.
Pi lists them in the system prompt and loads them via `read` when relevant.
Invoke explicitly: `/skill:add-feature`, `/skill:fix-bug`, `/skill:review`,
`/skill:implement-spec`, `/skill:maintain`.

### Context loading

Pi auto-loads `AGENTS.md` from `~/.pi/agent/`, then walks up from cwd to `/`.
This repo's `AGENTS.md` is always included when Pi starts from inside the repo.

## Model Selection

Full benchmark data: `~/GIT/llm-test-bench/models/2x24gb.txt`
Detailed flags and caveats: `memory/models.md`

Key models for 4090+3090 (48 GB):

| Model file | Speed | Score | Notes |
|---|---|---|---|
| Qwen3.6-35B-A3B-MTP-MXFP4_MOE.gguf | 121 tok/s | 32/33 | **default** — best all-round |
| Qwen3-Coder-30B-A3B-Instruct-1M-Q4_K_M.gguf | ~115 tok/s | 19/19 coding | 1M ctx window |
| Qwen_Qwen3.5-35B-A3B-Q4_K_M.gguf | 153 tok/s | — | thinking, 1M ctx |
| Qwen3.6-35B-A3B-UD-Q4_K_M.gguf | 146 tok/s | — | thinking, ctx_256k: 82 tok/s |
| Qwen_Qwen3.6-27B-Q4_K_M.gguf | 40 tok/s | 32/33 | dense, f16 KV required |
| Qwen2.5-Coder-32B-Instruct-Q4_K_M.gguf | 37 tok/s | 19/19 coding | ctx silently caps at 32k |

## Hardware

- CPU: AMD Ryzen 9 9900X (20 cores)
- RAM: ~86 GB DDR5
- GPU 0: RTX 4090 24 GB (~1008 GB/s)
- GPU 1: RTX 3090 24 GB (~936 GB/s)
- Interconnect: PCIe only (no NVLink — limits 70B tensor-parallel to ~20 tok/s)
