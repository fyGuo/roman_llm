#!/usr/bin/env bash
# Report what the VM offers: OS, CPU/RAM, GPU, disk, sudo, internet, existing ollama.
# Run this first on the platform and keep the output — it decides how to install.
set -uo pipefail
source "$(dirname "$0")/../config.env"

section() { printf '\n=== %s ===\n' "$1"; }

section "OS"
uname -a
[ -f /etc/os-release ] && grep -E '^(NAME|VERSION)=' /etc/os-release

section "CPU / RAM"
echo "CPU cores: $(nproc 2>/dev/null || echo unknown)"
free -h 2>/dev/null || echo "free not available"

section "GPU"
if command -v nvidia-smi >/dev/null 2>&1; then
  nvidia-smi --query-gpu=name,memory.total,driver_version --format=csv
elif command -v rocm-smi >/dev/null 2>&1; then
  rocm-smi --showproductname --showmeminfo vram
else
  echo "No NVIDIA/AMD GPU tools found -> Ollama will run on CPU (slower; prefer models <= 8B)."
fi

section "Disk (model dir: $OLLAMA_MODELS)"
mkdir -p "$OLLAMA_MODELS" 2>/dev/null
df -h "$OLLAMA_MODELS" 2>/dev/null || df -h "$HOME"

section "Privileges"
if sudo -n true 2>/dev/null; then
  echo "sudo: available (passwordless)"
else
  echo "sudo: NOT available -> install_ollama.sh will do a user-local install"
fi

section "Internet"
if curl -fsS --max-time 10 -o /dev/null https://ollama.com; then
  echo "ollama.com: reachable"
else
  echo "ollama.com: NOT reachable -> see 'Offline install' in README.md"
fi

section "Existing Ollama"
if command -v ollama >/dev/null 2>&1; then
  echo "found: $(command -v ollama)"
  ollama --version 2>/dev/null
else
  echo "ollama not on PATH"
fi

section "Python"
command -v python3 >/dev/null 2>&1 && python3 --version || echo "python3 not found"
