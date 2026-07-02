# Architecture

## Model Server

- Binary: `llama-server` (`~/.local/bin/llama-server` → `~/GIT/llama.cpp/build/bin/llama-server`)
- Default model: `Qwen3.6-35B-A3B-MTP-MXFP4_MOE.gguf` (noctrex-qwen3.6:35b)
- Models dir: `~/GIT/llm-test-bench/allmodels/`
- Port: 8080, OpenAI-compatible API at `http://127.0.0.1:8080/v1`
- GPU: RTX 4090 (dev 0) + RTX 3090 (dev 1), tensor_split=1,1, no NVLink

## Coding CLI

- Pi `@earendil-works/pi-coding-agent` v0.80.3
- Install: `~/.local/share/npm-global/bin/pi`
- Config: `~/.pi/agent/models.json` → provider `llama-local`, model id `local`
- Start with: `pi --model llama-local/local`

## Model Selection

Available models in `~/GIT/llm-test-bench/allmodels/` — benchmarked in `~/GIT/llm-test-bench/`.
See `~/GIT/llm-test-bench/models/2x24gb.txt` for confirmed params and benchmark scores.

Key models for 4090+3090 (48 GB):
| Model file | Speed | Score | Notes |
|---|---|---|---|
| Qwen3.6-35B-A3B-MTP-MXFP4_MOE.gguf | 121 tok/s | 32/33 | **default** |
| Qwen3-Coder-30B-A3B-Instruct-1M-Q4_K_M.gguf | ~115 tok/s | 19/19 coding | 1M context |
| Qwen_Qwen3.5-35B-A3B-Q4_K_M.gguf | 153 tok/s | — | thinking, 1M ctx |
| Qwen3.6-35B-A3B-UD-Q4_K_M.gguf | 146 tok/s | — | thinking |

## Hardware

- CPU: AMD Ryzen 9 9900X (20 cores)
- RAM: ~86 GB DDR5
- GPU 0: RTX 4090 24 GB
- GPU 1: RTX 3090 24 GB
- PCIe only (no NVLink)
