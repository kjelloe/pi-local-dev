#!/usr/bin/env bash
# Starts llama-server for local AI development.
# Default model: noctrex-qwen3.6:35b (Qwen3.6-35B-A3B-MTP-MXFP4_MOE, 32/33 tasks, ~121 tok/s)
# Default context: 65536 tokens
# Port: 8080

set -euo pipefail

MODELS_DIR="${LLAMA_MODELS_DIR:-$HOME/GIT/llm-test-bench/allmodels}"
BIN="${LLAMA_SERVER_BIN:-llama-server}"
MODEL="${MODEL:-Qwen3.6-35B-A3B-MTP-MXFP4_MOE.gguf}"
CTX="${CTX:-65536}"
PORT="${PORT:-8080}"

exec "$BIN" \
  -m "$MODELS_DIR/$MODEL" \
  --ctx-size "$CTX" \
  --port "$PORT" \
  --host 127.0.0.1 \
  --n-gpu-layers 999 \
  --no-mmap \
  --tensor-split 1,1 \
  --cache-type-k f16 \
  --cache-type-v f16 \
  --flash-attn on \
  --batch-size 512 \
  --ubatch-size 128 \
  "$@"
