#!/usr/bin/env bash
# Install uv (no sudo needed) and create .venv with the pinned Python + locked dependencies.
# Python version: .python-version   Dependencies: pyproject.toml / uv.lock
set -euo pipefail
source "$(dirname "$0")/../config.env"

export PATH="$HOME/.local/bin:$PATH"

if ! command -v uv >/dev/null 2>&1; then
  echo "Installing uv into ~/.local/bin"
  curl -LsSf https://astral.sh/uv/install.sh | sh
fi
uv --version

cd "$REPO_DIR"
# Downloads the pinned Python if the VM doesn't have it, then installs exactly what uv.lock lists.
uv sync --locked

echo
echo "Done. Run Python code with:  uv run python/ollama_client.py \"your prompt\""
echo "To use 'uv' in your own shell, add this to ~/.bashrc:"
echo "  export PATH=\"\$HOME/.local/bin:\$PATH\""
