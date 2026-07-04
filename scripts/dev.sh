#!/usr/bin/env bash
# Start llama-server (if not running) then launch Pi in this repo.
set -euo pipefail

HEALTH_URL="http://127.0.0.1:8080/health"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(dirname "$SCRIPT_DIR")"

_server_ready() {
    curl -sf --max-time 2 "$HEALTH_URL" 2>/dev/null | grep -q '"ok"'
}

if _server_ready; then
    echo "[dev] llama-server already running"
else
    echo "[dev] Starting llama-server..."
    "$SCRIPT_DIR/start-llama.sh" > /tmp/llama-server.log 2>&1 &
    echo "[dev] Waiting for server (log: /tmp/llama-server.log)..."
    for i in $(seq 1 90); do
        _server_ready && break
        sleep 1
        if [[ $i -eq 90 ]]; then
            echo "[dev] ERROR: llama-server did not become ready after 90s"
            echo "[dev] Last log lines:"
            tail -20 /tmp/llama-server.log
            exit 1
        fi
    done
    echo "[dev] llama-server ready"
fi

cd "$REPO_DIR"
exec pi "$@"
