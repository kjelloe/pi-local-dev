#!/usr/bin/env bash
# Named preset for hard/L6-style tasks: always (re)starts llama-server with the confirmed
# node_paratrooper (L6-full) config — qwen3.8:27b, single GPU, large context, bounded reasoning
# budget — then launches Pi against the current directory, same as dev.sh.
#
# Unlike dev.sh (which reuses an already-running server to avoid reload cost), this always stops
# and restarts: switching TO this profile is a deliberate, infrequent action, so correctness
# matters more than the ~15-90s reload it costs. See memory/decisions.md (2026-08-16/17) for why
# this preset exists — a plain `localai` run silently picked up the wrong (default) model twice
# before this was added.
set -euo pipefail

HEALTH_URL="http://127.0.0.1:8080/health"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(dirname "$SCRIPT_DIR")"

_server_ready() {
    curl -sf --max-time 2 "$HEALTH_URL" 2>/dev/null | grep -q '"ok"'
}

echo "[dev-reasoning] stopping any running llama-server..."
"$SCRIPT_DIR/stop-llama.sh" > /dev/null

echo "[dev-reasoning] starting qwen3.8:27b (single GPU, ctx=131072, reasoning-budget=20000)..."
CUDA_VISIBLE_DEVICES=0 \
MODEL="${MODEL:-Qwen3.8-27B-Q4_K_M.gguf}" \
CTX="${CTX:-131072}" \
  "$SCRIPT_DIR/start-llama.sh" \
  --reasoning on --tensor-split 1 --reasoning-budget "${REASONING_BUDGET:-20000}" \
  --reasoning-budget-message "I have thought enough, time to answer." \
  > /tmp/llama-server.log 2>&1 &

echo "[dev-reasoning] Waiting for server (log: /tmp/llama-server.log)..."
for i in $(seq 1 90); do
    _server_ready && break
    sleep 1
    if [[ $i -eq 90 ]]; then
        echo "[dev-reasoning] ERROR: llama-server did not become ready after 90s"
        echo "[dev-reasoning] Last log lines:"
        tail -20 /tmp/llama-server.log
        exit 1
    fi
done
echo "[dev-reasoning] llama-server ready"

"$SCRIPT_DIR/set-model-profile.py" reasoning

exec pi --provider llama-local --model local --skill "$REPO_DIR/skills" "$@"
