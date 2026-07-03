# Pattern: Starting the Model Server

## Default (noctrex-qwen3.6:35b, 65k ctx)

```bash
./scripts/start-llama.sh
```

Wait for: `llama server listening at http://127.0.0.1:8080`

Then start Pi:

```bash
pi --model llama-local/local
```

## Override Model

All overrides via env vars. Check `memory/models.md` for available models and their filenames.

```bash
# Long-context coding tasks
MODEL=Qwen3-Coder-30B-A3B-Instruct-1M-Q4_K_M.gguf CTX=131072 ./scripts/start-llama.sh

# Fastest thinking model
MODEL=Qwen_Qwen3.5-35B-A3B-Q4_K_M.gguf ./scripts/start-llama.sh

# Force single GPU (4090 only — faster for models that fit in 24 GB)
CUDA_VISIBLE_DEVICES=0 ./scripts/start-llama.sh
```

## Health Check

```bash
curl -s http://127.0.0.1:8080/health | python3 -m json.tool
# Expect: {"status": "ok"}
```

## Restart After Model Switch

Kill the running server (`Ctrl-C` or `kill $(lsof -ti:8080)`), then relaunch with the new
`MODEL=` env var. Pi does not need to be restarted — it reconnects on the next request.

## Troubleshooting

- **Server not ready**: Large models with `--no-mmap` can take 30-90 seconds to load. Watch stdout.
- **Port in use**: `lsof -ti:8080 | xargs kill`
- **CUDA OOM**: Reduce `CTX` or switch to a smaller model. See `memory/gotchas.md` for ctx caps.
- **Low throughput**: Confirm `tensor_split` is active and both GPUs are listed by `nvidia-smi`.
