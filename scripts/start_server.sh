#!/usr/bin/env bash
# Start `ollama serve` in the background (survives closing the terminal).
# Logs: run/ollama.log   PID: run/ollama.pid
set -euo pipefail
source "$(dirname "$0")/../config.env"

mkdir -p "$RUN_DIR" "$OLLAMA_MODELS"
PID_FILE="$RUN_DIR/ollama.pid"
LOG_FILE="$RUN_DIR/ollama.log"

if curl -fsS --max-time 3 "http://$OLLAMA_HOST/api/version" >/dev/null 2>&1; then
  echo "Ollama server already running at http://$OLLAMA_HOST"
  exit 0
fi

command -v ollama >/dev/null 2>&1 || { echo "ollama not found. Run scripts/install_ollama.sh first."; exit 1; }

echo "Starting ollama serve on $OLLAMA_HOST (models in $OLLAMA_MODELS)"
nohup ollama serve >>"$LOG_FILE" 2>&1 &
echo $! >"$PID_FILE"

for _ in $(seq 1 30); do
  if curl -fsS --max-time 2 "http://$OLLAMA_HOST/api/version" >/dev/null 2>&1; then
    echo "Server up (pid $(cat "$PID_FILE")). Logs: $LOG_FILE"
    exit 0
  fi
  sleep 1
done

echo "Server did not come up within 30s. Last log lines:"
tail -n 30 "$LOG_FILE"
exit 1
