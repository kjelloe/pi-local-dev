#!/usr/bin/env bash
# Stops llama-server and releases its VRAM. Use when you're done coding for a while —
# the server otherwise stays running between Pi sessions (see memory/decisions.md, 2026-07-04).
set -euo pipefail

PORT="${PORT:-8080}"
PIDFILE="/tmp/llama-server-${PORT}.pid"

_is_llama_server() {
  [[ -d "/proc/$1" ]] && grep -q llama-server "/proc/$1/comm" 2>/dev/null
}

PID=""
if [[ -f "$PIDFILE" ]]; then
  candidate="$(cat "$PIDFILE")"
  if _is_llama_server "$candidate"; then
    PID="$candidate"
  else
    echo "[stop] stale pidfile ($PIDFILE), ignoring"
    rm -f "$PIDFILE"
  fi
fi

if [[ -z "$PID" ]]; then
  # Fallback for servers started before this pidfile existed, or started manually.
  PID="$(lsof -ti:"$PORT" 2>/dev/null | head -1)"
fi

# Stop hwmonitor.py first (if we started one) so it doesn't try to pause/resume a server
# that's about to go away, and to release its own pidfile.
HWPIDFILE="/tmp/hwmonitor-${PORT}.pid"
if [[ -f "$HWPIDFILE" ]]; then
  hwpid="$(cat "$HWPIDFILE")"
  kill "$hwpid" 2>/dev/null || true
  rm -f "$HWPIDFILE"
  echo "[stop] stopped hwmonitor (pid $hwpid)"
fi

if [[ -z "$PID" ]]; then
  echo "[stop] no llama-server found on port $PORT"
  exit 0
fi

echo "[stop] stopping llama-server (pid $PID, port $PORT)..."
kill -CONT "$PID" 2>/dev/null || true  # in case hwmonitor left it paused
kill "$PID"
for i in $(seq 1 15); do
  _is_llama_server "$PID" || break
  sleep 1
  if [[ $i -eq 15 ]]; then
    echo "[stop] still running after 15s, sending SIGKILL"
    kill -9 "$PID" 2>/dev/null || true
  fi
done

rm -f "$PIDFILE"
echo "[stop] llama-server stopped"

if command -v nvidia-smi >/dev/null 2>&1; then
  nvidia-smi --query-gpu=index,memory.used,memory.total --format=csv
fi
