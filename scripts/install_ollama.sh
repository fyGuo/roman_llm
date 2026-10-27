#!/usr/bin/env bash
# Install Ollama.
#   - With passwordless sudo: uses the official installer (system-wide).
#   - Without sudo: downloads the Linux release into $OLLAMA_INSTALL_DIR (no root needed).
#   - Offline: place the release archive in ./offline/ and it will be used instead of downloading.
# Usage: bash scripts/install_ollama.sh [--user]   (--user forces the no-sudo install)
set -euo pipefail
source "$(dirname "$0")/../config.env"

if command -v ollama >/dev/null 2>&1; then
  echo "Ollama already installed: $(command -v ollama) ($(ollama --version 2>/dev/null))"
  exit 0
fi

FORCE_USER=0
[ "${1:-}" = "--user" ] && FORCE_USER=1

if [ "$FORCE_USER" -eq 0 ] && sudo -n true 2>/dev/null; then
  echo "sudo available -> running official installer"
  curl -fsSL https://ollama.com/install.sh | sh
  exit 0
fi

echo "User-local install into $OLLAMA_INSTALL_DIR"
case "$(uname -m)" in
  x86_64)  ARCH=amd64 ;;
  aarch64|arm64) ARCH=arm64 ;;
  *) echo "Unsupported architecture: $(uname -m)"; exit 1 ;;
esac

mkdir -p "$OLLAMA_INSTALL_DIR"
OFFLINE_DIR="$REPO_DIR/offline"
ARCHIVE=""

# 1) Prefer a pre-downloaded archive (for VMs without internet).
for f in "$OFFLINE_DIR"/ollama-linux-"$ARCH".tar.zst "$OFFLINE_DIR"/ollama-linux-"$ARCH".tgz; do
  [ -f "$f" ] && ARCHIVE="$f" && break
done

# 2) Otherwise download. Newer releases ship .tar.zst, older ones .tgz — try both.
if [ -z "$ARCHIVE" ]; then
  TMP="$(mktemp -d)"
  trap 'rm -rf "$TMP"' EXIT
  for ext in tar.zst tgz; do
    url="https://ollama.com/download/ollama-linux-$ARCH.$ext"
    echo "Trying $url"
    if curl -fL --retry 3 -o "$TMP/ollama.$ext" "$url"; then
      ARCHIVE="$TMP/ollama.$ext"
      break
    fi
  done
fi

[ -n "$ARCHIVE" ] || { echo "Could not obtain Ollama archive. See 'Offline install' in README.md"; exit 1; }

echo "Extracting $ARCHIVE"
case "$ARCHIVE" in
  *.tar.zst)
    command -v zstd >/dev/null 2>&1 || { echo "zstd is required to extract .tar.zst (or provide the .tgz in ./offline/)"; exit 1; }
    zstd -dc "$ARCHIVE" | tar -x -C "$OLLAMA_INSTALL_DIR" ;;
  *.tgz)
    tar -xzf "$ARCHIVE" -C "$OLLAMA_INSTALL_DIR" ;;
esac

"$OLLAMA_INSTALL_DIR/bin/ollama" --version || true
echo
echo "Installed. Scripts in this repo find it automatically via config.env."
echo "To use 'ollama' in your own shell, add this to ~/.bashrc:"
echo "  export PATH=\"$OLLAMA_INSTALL_DIR/bin:\$PATH\""
