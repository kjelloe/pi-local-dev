# Pattern: Starting the System

## Preferred: one command

```bash
localai              # from anywhere (alias in ~/.bashrc)
./scripts/dev.sh     # from the repo
```

`dev.sh` starts llama-server if it isn't running, waits for readiness, then execs Pi.
AGENTS.md is auto-loaded. All skills are available as `/skill:name`.

## Server only (no Pi)

Use when benchmarking, testing the API directly, or running multiple sessions.

```bash
./scripts/start-llama.sh
```

Wait for: `llama server listening at http://127.0.0.1:8080`

Then start Pi separately:

```bash
pi     # default model set in .pi/settings.json
```

## Override Model or Context

All overrides via env vars. Check `memory/models.md` for available models and their filenames.

```bash
# Long-context coding tasks (1M context)
MODEL=Qwen3-Coder-30B-A3B-Instruct-1M-Q4_K_M.gguf CTX=131072 ./scripts/start-llama.sh

# Fastest thinking model
MODEL=Qwen_Qwen3.5-35B-A3B-Q4_K_M.gguf ./scripts/start-llama.sh

# Force single GPU (4090 only — faster for models that fit in 24 GB)
CUDA_VISIBLE_DEVICES=0 ./scripts/start-llama.sh
```

## Health Check

```bash
bash tests/test-server-health.sh
# or manually:
curl -s http://127.0.0.1:8080/health
```

## Restart After Model Switch

Kill the running server (`Ctrl-C` or `lsof -ti:8080 | xargs kill`), then relaunch with the
new `MODEL=` env var. Pi does not need to be restarted — it reconnects on the next request.

## Troubleshooting

- **Server not ready after 90 s**: check `/tmp/llama-server.log` for the error.
- **Port in use**: `lsof -ti:8080 | xargs kill`
- **CUDA OOM**: reduce `CTX` or switch to a smaller model. See `memory/gotchas.md` for ctx caps.
- **Low throughput**: confirm both GPUs are visible (`nvidia-smi`) and `tensor_split` is active.
- **Pi can't connect**: run `bash tests/test-server-health.sh` to confirm server is up.
- **Skills not appearing**: verify `.pi/settings.json` has `"skills": ["./skills"]` and that
  each `SKILL.md` has a non-empty `description:` in its frontmatter.
