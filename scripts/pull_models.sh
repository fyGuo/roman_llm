#!/usr/bin/env bash
# Download the models listed in OLLAMA_MODELS_TO_PULL (config.env). Server must be running.
# Usage: bash scripts/pull_models.sh [model ...]   (args override config.env)
set -euo pipefail
source "$(dirname "$0")/../config.env"

MODELS=("$@")
[ ${#MODELS[@]} -eq 0 ] && read -r -a MODELS <<<"$OLLAMA_MODELS_TO_PULL"

for m in "${MODELS[@]}"; do
  echo ">>> pulling $m"
  ollama pull "$m"
done

echo
ollama list
