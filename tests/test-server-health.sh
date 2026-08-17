#!/usr/bin/env bash
# Smoke test: confirms llama-server is running and healthy on port 8080.
set -euo pipefail

URL="http://127.0.0.1:8080/health"
TIMEOUT=5

status=$(curl -sf --max-time "$TIMEOUT" "$URL" 2>/dev/null) || {
  echo "FAIL: llama-server not reachable at $URL"
  exit 1
}

if echo "$status" | grep -q '"ok"'; then
  echo "OK: llama-server healthy"
else
  echo "FAIL: unexpected health response: $status"
  exit 1
fi

# Quick completions check
payload='{"model":"local","messages":[{"role":"user","content":"Reply with the single word: ready"}],"max_tokens":8}'
result=$(curl -sf --max-time 30 "http://127.0.0.1:8080/v1/chat/completions" \
  -H "Content-Type: application/json" \
  -d "$payload" 2>/dev/null) || {
  echo "FAIL: completions endpoint not responding"
  exit 1
}

echo "OK: completions endpoint responding"
echo "Response: $(echo "$result" | python3 -c 'import sys,json; d=json.load(sys.stdin); print(d["choices"][0]["message"]["content"].strip())')"

# GPU distribution check: catches a --tensor-split that doesn't match the GPU count on this
# box (e.g. a 2-way split silently leaving a 3rd installed GPU idle).
if command -v nvidia-smi >/dev/null 2>&1; then
  gpu_count=$(nvidia-smi --query-gpu=count --format=csv,noheader,nounits | head -1)
  used=$(nvidia-smi --query-gpu=memory.used --format=csv,noheader,nounits)
  idle_gpus=$(echo "$used" | awk '$1 < 500' | wc -l)
  if [[ "$idle_gpus" -gt 0 ]]; then
    echo "FAIL: $idle_gpus of $gpu_count GPU(s) idle (<500 MiB used) while server is running — tensor-split may not match installed GPU count"
    exit 1
  fi
  echo "OK: all $gpu_count GPU(s) show VRAM in use"
else
  echo "SKIP: nvidia-smi not found, cannot check GPU distribution"
fi
