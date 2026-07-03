# Models

All models live in `~/GIT/llm-test-bench/allmodels/`. Benchmarks confirmed on RTX 4090+3090 (48 GB).
Full benchmark data: `~/GIT/llm-test-bench/models/2x24gb.txt`

## Default: noctrex-qwen3.6:35b

```
Qwen3.6-35B-A3B-MTP-MXFP4_MOE.gguf
```

32/33 tasks, 121 tok/s. Best all-round model. MXFP4+MTP format requires Ampere+ (both 4090 and 3090 qualify).
Run WITHOUT speculative decoding flags — MTP breaks temp=0 determinism when used for spec decoding.

llama-server flags: `--n-gpu-layers 999 --no-mmap --tensor-split 1,1 --cache-type-k f16 --cache-type-v f16 --flash-attn on --batch-size 512 --ubatch-size 128`

## Coding Specialist: qwen3-coder:30b-1m

```
Qwen3-Coder-30B-A3B-Instruct-1M-Q4_K_M.gguf
```

Perfect coding score (19/19), 1M context window, ~115 tok/s. Best for long-file coding tasks.
Context speeds on 48 GB: 80.6 / 54.4 / 39.4 / 19.5 tok/s at 32k/64k/128k/256k.

llama-server flags: same as default plus `--tensor-split 1,1`

## Thinking Models (best speed)

```
Qwen_Qwen3.5-35B-A3B-Q4_K_M.gguf   # 153 tok/s, thinking, 1M ctx
Qwen3.6-35B-A3B-UD-Q4_K_M.gguf     # 146 tok/s, thinking, context_256k: 82.1 tok/s
```

Both use `cache_type_k=f16,cache_type_v=f16` and `tensor_split=1|1`. Add `--thinking` flag.
Note: qwen3.5 uses bartowski variant — do NOT use HauhauCS (fails context_128k).

## Dense Coding Models

```
Qwen_Qwen3.6-27B-Q4_K_M.gguf       # 40 tok/s, 32/33, f16 KV required (q8_0 fails hashmap)
Qwen_Qwen3.5-27B-Q4_K_M.gguf       # 42 tok/s, q8_0 KV OK, context_256k PASS
Qwen2.5-Coder-32B-Instruct-Q4_K_M.gguf  # 37 tok/s, perfect coding 19/19, ctx caps at 32k
Devstral-Small-2-24B-Instruct-2512-Q4_K_M.gguf  # 44 tok/s, dense 24B
```

## Context Window Caveats

- `Qwen2.5-Coder-32B-Q4_K_M`: server silently caps at 32768 even on 48 GB — use `max_ctx=32768`.
- `Qwen2.5-Coder-14B-Q4_K_M`: same cap at 32768 (unexplained VRAM accounting).
- `DeepSeek-R1-32B-Q5_K_M`: hard arch limit 131072 — use `max_ctx=131072` to prevent crash.
- `Huihui-Qwen3-Next-80B MXFP4`: context_256k OOM (~41 GB weights leaves <7 GB KV) — use `max_ctx=131072`.

## Switching Models

```bash
MODEL=Qwen3-Coder-30B-A3B-Instruct-1M-Q4_K_M.gguf CTX=131072 ./scripts/start-llama.sh
```

Pi reuses the same `llama-local/local` provider regardless of which model is running.
