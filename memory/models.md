# Models

All models live in `~/GIT/llm-test-bench/allmodels/`. Confirmed benchmark data:
`~/GIT/llm-test-bench/CLAUDE.md` and `~/GIT/llm-test-bench/reports/models-status-August-2026.md`.

This system currently has 3×24 GB (RTX 4090 + RTX 3090 + RTX 3090, 72 GB total, no NVLink). The
tables below also cover 1×24 GB (run with `CUDA_VISIBLE_DEVICES=0`, no `--tensor-split`), 2×24 GB
(run with `CUDA_VISIBLE_DEVICES=0,1` or `--tensor-split 1,1`), and 32 GB single card — useful
fallback tiers if `CUDA_VISIBLE_DEVICES` restricts to fewer GPUs for testing.

## Choosing a model by role

Two roles map to this repo's skills: **Coder** (`add-feature`, `fix-bug` — raw throughput,
correct code) and **Architect/Reviewer** (`review`, `implement-spec` — deep reasoning, full
context, catches subtle state-management bugs). `maintain` can use either.

| Tier | Coder pick | Architect/Reviewer pick |
|---|---|---|
| 1×24 GB | qwen3.8:27b — 45 tok/s, 19/19 coding | qwen3.8:27b — same model, Skill L6-full |
| 32 GB (single card, **projected, not directly benchmarked**) | qwen3.5:27b — ~30 tok/s est., 19/19 | qwen3.5:27b — Skill L6, 256k ctx at full speed |
| 2×24 GB (fallback tier) | qwopus3.6:35b — 161 tok/s, 19/19 coding | qwen3.5:27b — 28 tok/s, Skill L6 (full profile) |
| 3×24 GB (**this system**) | qwopus3.6:35b — 161 tok/s, 19/19 coding (still fastest, doesn't need 3rd GPU) | gpt-oss:120b — 56 tok/s, 19/19 coding + 4/4 web + full L6, thinking, 128k ctx |

qwen3.8:27b is the standout at 1×24 GB: it's the only model confirmed to pass the from-scratch
`node_paratrooper` (L6-full) task — deep multi-step game-state reasoning that every other model,
including 235B-parameter ones, fails. Needs a llama-server build ≥ 2026-08-13 (this repo's
`~/.local/bin/llama-server` — confirm with `llama-server --version`, commit ≥ `27df9199d`).

qwopus3.6:35b vs gpt-oss:120b at this system's actual tier (3×24 GB) is now a clean win for
gpt-oss:120b on depth, without giving up much speed: gpt-oss:120b is 19/19 coding + 4/4 web + the
full L6-stepped chain at 56 tok/s — actually *faster* than qwen3.5:27b's old 2×24 GB pick (28
tok/s) despite being far more capable, because the 3rd GPU makes it fully GPU-resident. qwopus
remains the default for implementation-heavy work (`add-feature`, `fix-bug`) because it's still
5.75× faster than gpt-oss:120b and doesn't need the 3rd GPU (fits in ~20 GB); switch to
gpt-oss:120b for `/skill:review` or `/skill:implement-spec` planning. qwen3.5:27b stays documented
below as a lighter/faster fallback if only 2 GPUs are available (`CUDA_VISIBLE_DEVICES=0,1`).

## Model Details

### 1×24 GB (single RTX 4090, or `CUDA_VISIBLE_DEVICES=0` on this system)

**qwen3.8:27b** — `Qwen3.8-27B-Q4_K_M.gguf` (~18.4 GB, Gated DeltaNet hybrid, no Ampere+ required)
19/19 coding, 4/4 web, 4/4 L6-stepped, and the only confirmed L6-full pass. Requires f16 KV
(q8_0 causes a python_hashmap precision failure — same rule as qwen3.6:27b below). Throughput
collapses past 64k context on a single GPU (~10 tok/s at 128k, general large-KV bandwidth limit,
not architecture-specific) — use the 2×24 GB config below for reliable 128k+ context work.
**On this system specifically**: the L6-full pass only reproduces reliably with `CUDA_VISIBLE_DEVICES=0`
(true single-GPU). It's confirmed to reproducibly FAIL with `--tensor-split 1,1` (the 2×24 GB
config used everywhere else in this doc) — a cross-GPU floating-point reduction effect, not a
capability regression. Confirmed to PASS under 3-GPU auto-distribution (no explicit `tensor_split`
flag). **Open question, not resolved**: an explicit 3-way `--tensor-split 1,1,1` has never been
tested for this task — do not assume it passes or fails; it's simply untested. Not relevant unless
something genuinely needs the L6-full task specifically; coding/web/context all pass identically
across the tested configs.

```
--n-gpu-layers 999 --no-mmap --cache-type-k f16 --cache-type-v f16 \
--flash-attn on --batch-size 512 --ubatch-size 128 --reasoning on
```
Cap context at 131072 (`CTX=131072`) — architecture headroom, not a KV limit.

### 32 GB single card (RTX 5090 / A6000 / RTX 6000 Ada — **projected from 24 GB data, not directly benchmarked**)

**qwen3.5:27b** — `Qwen_Qwen3.5-27B-Q4_K_M.gguf` (~16 GB, dense, thinking)
At 32 GB the extra headroom removes the context ceiling seen at 24 GB — 256k context at full
speed instead of bandwidth-throttled. Same weights as the 2×24 GB entry below; run single-GPU,
no `--tensor-split`.

```
--n-gpu-layers 999 --no-mmap --cache-type-k q8_0 --cache-type-v q8_0 \
--flash-attn on --batch-size 512 --ubatch-size 128 --reasoning on
```

### 2×24 GB (fallback tier — `CUDA_VISIBLE_DEVICES=0,1`)

**qwopus3.6:35b** — `Qwopus3.6-35B-A3B-Coder-MXFP4_MOE_Q8_0-Imatrix.gguf` (~19.8 GB, MXFP4 MoE,
Ampere+ required — both 4090 and 3090 qualify). Fastest model with a perfect 19/19 coding score.
3/4 web (fails fastapi whitespace validation — coder-fine-tune-specific gap, not a general
capability issue).

```
--n-gpu-layers 999 --no-mmap --tensor-split 1,1 --cache-type-k f16 --cache-type-v f16 \
--flash-attn on --batch-size 512 --ubatch-size 128
```
Cap context at 131072.

**qwen3.5:27b** — `Qwen_Qwen3.5-27B-Q4_K_M.gguf` (~16 GB, dense, thinking, q8_0 KV safe).
Slower (28 tok/s) but the only model confirmed at Skill L6 on this exact hardware: 19/19 coding,
4/4 web, 4/4 L6-stepped (including `node_para_entities`, a multi-entity state-tracking task most
MoE models fail), 6/6 context through 256k.

```
--n-gpu-layers 999 --no-mmap --tensor-split 1,1 --cache-type-k q8_0 --cache-type-v q8_0 \
--flash-attn on --batch-size 512 --ubatch-size 128 --reasoning on
```
Cap context at 262144 (architecture supports it cleanly at this VRAM tier).

### 3×24 GB — this system

**gpt-oss:120b** — `gpt-oss-120b-MXFP4.gguf` (~60 GB, MXFP4 MoE, thinking). First model to
achieve perfect 19/19 coding + perfect 4/4 web simultaneously, plus the full L6-stepped chain.
Fully GPU-resident across 3 cards (single-GPU fallback needs `--n-cpu-moe 35` and drops to
~17 tok/s). Architect/Reviewer pick for this system — see "Choosing a model by role" above.

```
--n-gpu-layers 999 --no-mmap --tensor-split 1,1,1 --cache-type-k q8_0 --cache-type-v q8_0 \
--flash-attn on --batch-size 512 --ubatch-size 128 --reasoning on
```
Cap context at 131072 (architecture limit, `n_ctx_train=131072`).

Alternate: **qwen3.5-122b:a10b** — `Qwen3.5-122B-A10B-MXFP4_MOE-MTP-merged.gguf` (~65 GB) —
same 19/19+4/4 profile, MTP-merged (no separate spec-decode flag needed), ~37 tok/s (slower than
gpt-oss:120b but breaks the same A3B MoE capability ceilings on `python_hashmap` and
`node_para_core`).

## Thinking Models (fastest, non-role-specific)

```
Qwen_Qwen3.5-35B-A3B-Q4_K_M.gguf   # 153 tok/s, thinking, 1M ctx
Qwen3.6-35B-A3B-UD-Q4_K_M.gguf     # 146 tok/s, thinking, context_256k: 82.1 tok/s
```

Both use `--cache-type-k f16 --cache-type-v f16 --tensor-split 1,1 --reasoning on`.
Note: qwen3.5 uses the bartowski variant — do NOT use the HauhauCS one (fails context_128k).

## Dense Coding Models (other options at 2×24 GB)

```
Qwen_Qwen3.6-27B-Q4_K_M.gguf       # 40 tok/s, 19/19, f16 KV required (q8_0 fails hashmap)
Qwen2.5-Coder-32B-Instruct-Q4_K_M.gguf  # 37 tok/s, perfect coding 19/19, ctx caps at 32k
Devstral-Small-2-24B-Instruct-2512-Q4_K_M.gguf  # 44 tok/s, dense 24B
```

## Context Window Caveats

- `Qwen2.5-Coder-32B-Q4_K_M`: server silently caps at 32768 even on 48 GB — use `CTX=32768`.
- `Qwen2.5-Coder-14B-Q4_K_M`: same cap at 32768 (unexplained VRAM accounting).
- `DeepSeek-R1-32B-Q5_K_M`: hard arch limit 131072 — use `CTX=131072` to prevent crash.
- `Huihui-Qwen3-Next-80B MXFP4`: context_256k OOM (~41 GB weights leaves <7 GB KV) — use `CTX=131072`.
- `qwen3.8:27b` and `Qwen_Qwen3.6-27B` single-GPU: throughput collapses past 64k context (general
  large-KV-model bandwidth limit at this VRAM tier, not a per-model bug). Use the 2×24 GB config
  for reliable 128k+ work with either.

## Switching Models

```bash
# Fast coding (default)
MODEL=Qwopus3.6-35B-A3B-Coder-MXFP4_MOE_Q8_0-Imatrix.gguf CTX=131072 ./scripts/start-llama.sh

# Deep review / spec planning (this system's tier)
MODEL=gpt-oss-120b-MXFP4.gguf CTX=131072 ./scripts/start-llama.sh

# Long-context coding (1M window)
MODEL=Qwen3-Coder-30B-A3B-Instruct-1M-Q4_K_M.gguf CTX=131072 ./scripts/start-llama.sh
```

Pi reuses the same `llama-local/local` provider regardless of which model is running.
