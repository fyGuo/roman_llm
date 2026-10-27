#!/usr/bin/env bash
# Stop the server started by start_server.sh.
set -euo pipefail
source "$(dirname "$0")/../config.env"

PID_FILE="$RUN_DIR/ollama.pid"
if [ -f "$PID_FILE" ] && kill -0 "$(cat "$PID_FILE")" 2>/dev/null; then
  kill "$(cat "$PID_FILE")"
  rm -f "$PID_FILE"
  echo "Stopped."
else
  echo "No running server found from $PID_FILE."
  echo "If ollama was installed system-wide it may run as a service: sudo systemctl stop ollama"
fi
