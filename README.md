# localdev

Local AI development system. Model server: llama-server. Coding CLI: Pi.
All project knowledge lives in this repo.

Doubles as a launcher for other projects: `localai` starts the server (if needed) and launches Pi
against your **current directory** — run it from `~/GIT/some-web-project` or `~/GIT/some-game` to
work on that project directly, with the local model and this repo's skills available everywhere.

## How to Use

### 1. Prerequisites

- An NVIDIA GPU (Ampere or newer for MXFP4 models), CUDA drivers installed.
- [`llama.cpp`](https://github.com/ggml-org/llama.cpp) built with CUDA support, with
  `llama-server` on your `PATH` (or set `LLAMA_SERVER_BIN` to its full path).
- [Pi](https://pi.dev) installed (`npm install -g @earendil-works/pi-coding-agent`), with `pi` on
  your `PATH`.
- GGUF model files downloaded to a local directory (default: `~/GIT/llm-test-bench/allmodels/`,
  override with `LLAMA_MODELS_DIR`).

### 2. Configure Pi's provider

Add a `llama-local` provider so Pi knows how to talk to your local server. Create or edit
`~/.pi/agent/models.json`:

```json
{
  "providers": {
    "llama-local": {
      "baseUrl": "http://127.0.0.1:8080/v1",
      "api": "openai-completions",
      "apiKey": "local",
      "compat": {
        "supportsDeveloperRole": false,
        "supportsReasoningEffort": false
      },
      "models": [
        { "id": "local", "name": "local model", "contextWindow": 65536, "maxTokens": 16384 }
      ]
    }
  }
}
```

This is global (`~/.pi/agent/`), not part of this repo — it applies no matter which project
directory you run Pi from.

### 3. Clone this repo and add the `localai` alias

```bash
git clone <this-repo-url> ~/GIT/localdev
```

Add to `~/.bashrc` (or `~/.zshrc`):

```bash
alias localai='~/GIT/localdev/scripts/dev.sh'
alias localai-stop='~/GIT/localdev/scripts/stop-llama.sh'
```

Then `source ~/.bashrc` (or open a new shell).

### 4. Launch it

`localai` starts `llama-server` if it isn't already running (polls `/health` for up to 90s), then
launches Pi in your **current directory** with the local model and this repo's skills available.

```bash
# Work on this repo itself
cd ~/GIT/localdev
localai

# Work on any other project — same command, no per-project setup needed
cd ~/GIT/some-web-project
localai

cd ~/GIT/some-game
localai
```

Pi picks up that project's own `AGENTS.md`/`CLAUDE.md` automatically (Pi walks up from cwd), so
each project keeps its own conventions while sharing this repo's model and skills.

### 5. Use the skills

Inside a Pi session, invoke a skill by name — see the table below. Each skill tells Pi which
model to prefer (fast Coder pick vs. deeper Architect/Reviewer pick — see `memory/models.md`),
what steps to follow, and what to update in the repo's knowledge base afterward.

```
/skill:add-feature   Implement a login form for this app
/skill:fix-bug        The /api/users endpoint returns 500 on empty body
/skill:review
```

### 6. Switch models when you need more depth or a different context window

```bash
MODEL=gpt-oss-120b-MXFP4.gguf CTX=131072 ./scripts/start-llama.sh   # deep review / planning
MODEL=Qwen3-Coder-30B-A3B-Instruct-1M-Q4_K_M.gguf CTX=131072 ./scripts/start-llama.sh  # 1M ctx
MODEL=Qwen_Qwen3.5-35B-A3B-Q4_K_M.gguf ./scripts/start-llama.sh  # fastest, 153 tok/s
CUDA_VISIBLE_DEVICES=0 ./scripts/start-llama.sh  # single-GPU — faster for small MoE models
```

Restart Pi after switching — it reconnects to whatever `llama-server` is currently serving. See
`memory/models.md` for the full model-by-role picks and this system's hardware tier.

### 7. Verify the server is healthy

```bash
bash tests/test-server-health.sh   # server smoke test: health, completions, GPU distribution
npm test                           # node:test suite (target project's own tests)
pytest tests/                      # Python suite (target project's own tests)
npx playwright test                # browser tests (target project's own tests)
```

`test-server-health.sh` checks `/health`, does a quick completions round-trip, and (if
`nvidia-smi` is available) confirms every installed GPU shows VRAM in use — catches a
`--tensor-split` that doesn't match your GPU count. The `npm`/`pytest`/`playwright` commands run
whichever test suite exists in the project you're currently working on with Pi, not this repo.

### 8. Release the server when you're done coding

`llama-server` is left running between Pi sessions on purpose — reloading a large MXFP4 model
takes 30-90s, so `localai` reuses whatever's already up rather than restarting it every time. When
you're done for a while and want the VRAM back (72 GB across 3 GPUs) for something else:

```bash
localai-stop
```

Idempotent — safe to run whether or not a server is currently up. Finds the server via a pidfile
`start-llama.sh` writes to `/tmp/llama-server-<port>.pid`, with a port-based fallback for servers
started before this existed or started manually. Next `localai` call just starts a fresh one.

### 9. Thermal watchdog (automatic)

`start-llama.sh` launches `scripts/hwmonitor.py` in the background alongside every server it
starts, polling GPU temp/junction/power and RAM every 2s. On a WARN threshold it just logs; on
CRIT (default: 95°C core / 100°C junction / 98% power draw) it **pauses** `llama-server` with
`SIGSTOP` — rather than killing it — and automatically resumes it with `SIGCONT` once temps
recover below WARN. A paused server just makes Pi's in-flight request hang until resumed, instead
of erroring out and losing the task.

```bash
localai-temps          # tail the live log
localai-stop           # also stops hwmonitor, resuming the server first if it was paused
HWMONITOR=0 localai     # skip the watchdog entirely for this session
```

Adapted from `~/GIT/llm-test-bench/hwmonitor/`, whose version aborts a resumable benchmark run on
CRIT — not appropriate here since it would drop an in-progress Pi coding task. See
`memory/decisions.md` (2026-08-16) for the pause-vs-abort rationale.

## Skills (slash commands inside Pi)

| Command | Purpose |
|---|---|
| `/skill:add-feature` | Load context → plan → implement → test → update docs |
| `/skill:fix-bug` | Find root cause → fix → add test → update gotchas |
| `/skill:review` | Correctness, scope, security review — no style nits |
| `/skill:implement-spec` | Plan (wait for approval) → small commits → extract knowledge |
| `/skill:maintain` | Periodic cleanup: extract knowledge, prune stale docs, review TODOs |

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
