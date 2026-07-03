# Design Decisions

## 2026-07-02 — noctrex-qwen3.6:35b as default model

Chose `Qwen3.6-35B-A3B-MTP-MXFP4_MOE.gguf` as the default for the startup script.

Rationale: 32/33 benchmark tasks at 121 tok/s on 4090+3090. Best overall score in the 2x24gb
suite. f16 KV avoids precision-boundary failures (e.g. python_hashmap). MXFP4 format is
supported by both Ampere GPUs in the system.

Alternative considered: `qwen3-coder:30b-1m` (perfect coding 19/19) — preferred when working
on large codebases that benefit from 1M context.

## 2026-07-02 — llama-server over Ollama

llama-server chosen as the inference backend (not Ollama) because:
- Direct control over quantization, KV type, batch size, tensor_split
- Benchmark harness (llm-test-bench) already uses llama-server
- Avoids Ollama model format conversion overhead
- Ollama pulls remain available for quick experiments (`ollama run ...`)

## 2026-07-02 — Pi as primary coding CLI

`@earendil-works/pi-coding-agent` chosen over Aider as primary because:
- Supports custom OpenAI-compatible providers (llama-server at port 8080)
- AGENTS.md convention aligns with this repo's knowledge structure
- Aider kept as optional second opinion

## 2026-07-02 — 65536 default context window

65536 chosen as the startup script default. Rationale:
- Fits comfortably in 48 GB for all supported models
- Sufficient for typical coding tasks and multi-file edits
- Override with `CTX=131072` for long-context tasks (qwen3-coder:30b-1m handles 1M)
