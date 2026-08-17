# Architecture

## Launch

```bash
localai              # alias: ~/GIT/localdev/scripts/dev.sh — run from any project directory
./scripts/dev.sh     # starts llama-server if not running, then launches Pi against cwd
localai-stop         # alias: ~/GIT/localdev/scripts/stop-llama.sh — release VRAM when done
```

`dev.sh` polls `/health` for up to 90 s, then execs `pi --provider llama-local --model local
--skill $REPO_DIR/skills "$@"` — it does not `cd`, so Pi operates on whatever directory it was
launched from (see `memory/decisions.md`, 2026-08-16).
Log while server starts: `/tmp/llama-server.log`

`llama-server` is deliberately left running between Pi sessions (avoids the 30-90 s reload cost —
see `memory/decisions.md`, 2026-07-04). Run `localai-stop` to release it and free VRAM
explicitly; `start-llama.sh` tracks its PID in `/tmp/llama-server-<port>.pid` for this.

`start-llama.sh` also launches `scripts/hwmonitor.py` in the background (`HWMONITOR=0` to skip) —
a thermal watchdog polling GPU temp/junction/power/RAM every 2s. On CRIT it pauses `llama-server`
(`SIGSTOP`) rather than killing it, auto-resuming (`SIGCONT`) once temps recover — preserves an
in-flight Pi request instead of dropping it. `localai-temps` tails the log. See
`memory/decisions.md` (2026-08-16) for why this diverges from llm-test-bench's abort-on-CRIT
`hwmonitor.py`.

## Model Server

- Binary: `~/.local/bin/llama-server` → `~/GIT/llama.cpp/build/bin/llama-server` (CUDA, Ampere+)
- Default model: `Qwopus3.6-35B-A3B-Coder-MXFP4_MOE_Q8_0-Imatrix.gguf` (qwopus3.6:35b — see `memory/decisions.md`, 2026-08-16)
- Models dir: `~/GIT/llm-test-bench/allmodels/` (`$LLAMA_MODELS_DIR`)
- API: OpenAI-compatible at `http://127.0.0.1:8080/v1`
- GPU: RTX 4090 (dev 0) + RTX 3090 (dev 1) + RTX 3090 (dev 2), `tensor_split=1,1,1`, no NVLink

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

Full benchmark data: `~/GIT/llm-test-bench/CLAUDE.md` and
`~/GIT/llm-test-bench/reports/models-status-August-2026.md`
Detailed flags, per-tier options, and caveats: `memory/models.md`

Two roles map to this repo's skills — **Coder** (`add-feature`, `fix-bug`: throughput, correct
code) and **Architect/Reviewer** (`review`, `implement-spec`: deep reasoning, full context).
Picks below are for this system's actual tier (3×24 GB, RTX 4090 + RTX 3090 + RTX 3090).
`memory/models.md` also covers 1×24 GB, 2×24 GB, and 32 GB single-card (projected) as fallback
tiers.

| Role | Model file | Speed | Score | Notes |
|---|---|---|---|---|
| Coder (**default**) | Qwopus3.6-35B-A3B-Coder-MXFP4_MOE_Q8_0-Imatrix.gguf | 161 tok/s | 19/19 coding | fastest perfect coder; 3/4 web (fastapi gap); only needs ~20 GB, doesn't benefit from 3rd GPU |
| Architect/Reviewer | gpt-oss-120b-MXFP4.gguf | 56 tok/s | 19/19 coding + 4/4 web + full L6 | fully GPU-resident across all 3 cards; thinking |
| Long-context coding | Qwen3-Coder-30B-A3B-Instruct-1M-Q4_K_M.gguf | ~115 tok/s | 19/19 coding | 1M ctx window |
| Fastest (general) | Qwen_Qwen3.5-35B-A3B-Q4_K_M.gguf | 153 tok/s | — | thinking, 1M ctx |

## Hardware

- CPU: AMD Ryzen 9 9900X (20 cores)
- RAM: ~86 GB DDR5
- GPU 0: RTX 4090 24 GB (~1008 GB/s)
- GPU 1: RTX 3090 24 GB (~936 GB/s)
- GPU 2: RTX 3090 24 GB (~936 GB/s)
- Interconnect: PCIe only (no NVLink — limits 70B tensor-parallel to ~20 tok/s)
