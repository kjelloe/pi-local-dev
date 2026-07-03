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
