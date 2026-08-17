#!/usr/bin/env bash
# Starts llama-server for local AI development.
# Hardware: RTX 4090 + RTX 3090 + RTX 3090 (72 GB total across 3 GPUs).
# Default model: qwopus3.6:35b (Qwopus3.6-35B-A3B-Coder-MXFP4_MOE, 19/19 coding, 161 tok/s)
# See memory/decisions.md (2026-08-16) for why this replaced noctrex-qwen3.6:35b.
# qwopus3.6:35b only needs ~20 GB and doesn't benefit from the 3rd GPU; the 3-way
# --tensor-split below is for parity with larger models (e.g. gpt-oss:120b) that need it.
# Default context: 65536 tokens
# Port: 8080
# Sampling: temp=0, seed=1 (deterministic — matches llm-test-bench's harness default; Pi doesn't
# send its own temperature, so this server default governs). Override per-run by passing
# --temp/--seed again as extra args — llama-server takes the last occurrence of a repeated flag.
# See memory/decisions.md (2026-08-16).

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MODELS_DIR="${LLAMA_MODELS_DIR:-$HOME/GIT/llm-test-bench/allmodels}"
BIN="${LLAMA_SERVER_BIN:-llama-server}"
MODEL="${MODEL:-Qwopus3.6-35B-A3B-Coder-MXFP4_MOE_Q8_0-Imatrix.gguf}"
CTX="${CTX:-65536}"
PORT="${PORT:-8080}"

# $$ survives the exec below (exec replaces the process image, not the PID), so this file
# always names the actual llama-server PID — stop-llama.sh reads it to release VRAM on demand.
echo $$ > "/tmp/llama-server-${PORT}.pid"

# Thermal watchdog — pauses (SIGSTOP) llama-server on a CRIT temp/power breach and auto-resumes
# once recovered. Set HWMONITOR=0 to skip. See memory/decisions.md (2026-08-16).
if [[ "${HWMONITOR:-1}" != "0" ]]; then
  "$SCRIPT_DIR/hwmonitor.py" --port "$PORT" --pid $$ --quiet \
    --log "/tmp/hwmonitor-${PORT}.log" > /dev/null 2>&1 &
  echo $! > "/tmp/hwmonitor-${PORT}.pid"
fi

exec "$BIN" \
  -m "$MODELS_DIR/$MODEL" \
  --ctx-size "$CTX" \
  --port "$PORT" \
  --host 127.0.0.1 \
  --n-gpu-layers 999 \
  --no-mmap \
  --tensor-split 1,1,1 \
  --cache-type-k f16 \
  --cache-type-v f16 \
  --flash-attn on \
  --batch-size 512 \
  --ubatch-size 128 \
  --temp 0 \
  --seed 1 \
  "$@"
