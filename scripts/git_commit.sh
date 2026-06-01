#!/bin/bash
# Schnell-Commit nach bestandener Uebung
# Usage: bash scripts/git_commit.sh [message]
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(dirname "$SCRIPT_DIR")"
MSG="${1:-C00: Fortschritt}"
cd "$REPO_ROOT"
git add -A
git status --short
git commit -m "$MSG" && git push origin main && echo "Gepusht!"
