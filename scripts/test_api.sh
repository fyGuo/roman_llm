#!/usr/bin/env bash
# Smoke test: hit the REST API with a one-shot prompt.
# Usage: bash scripts/test_api.sh [model]
set -euo pipefail
source "$(dirname "$0")/../config.env"

read -r -a ALL <<<"$OLLAMA_MODELS_TO_PULL"
MODEL="${1:-${ALL[0]}}"

echo "Server version:"
curl -fsS "http://$OLLAMA_HOST/api/version"; echo

echo "Asking $MODEL ..."
curl -fsS "http://$OLLAMA_HOST/api/generate" \
  -H 'Content-Type: application/json' \
  -d "{\"model\": \"$MODEL\", \"prompt\": \"Reply with exactly: OK, the model is working.\", \"stream\": false}" \
  | python3 -c 'import json,sys; r=json.load(sys.stdin); print(r["response"]); print(f"[{r.get(\"eval_count\",0)} tokens in {r.get(\"total_duration\",0)/1e9:.1f}s]")'
