#!/bin/bash
PEER_DIR="$1"
RED='\033[0;31m'; GREEN='\033[0;32m'; BOLD='\033[1m'; RESET='\033[0m'
TP=0; TT=0

echo -e "${BOLD}[1] count_files.sh vorhanden?${RESET}"; TT=$((TT+1))
[ -f "$PEER_DIR/count_files.sh" ] && { echo -e "${GREEN}✓${RESET}"; TP=$((TP+1)); } || { echo -e "${RED}✗${RESET}"; echo "SCORE:0/3"; exit 1; }

TMPDIR=$(mktemp -d); trap "rm -rf $TMPDIR" EXIT
mkdir -p "$TMPDIR/sub"; touch "$TMPDIR/a" "$TMPDIR/b" "$TMPDIR/sub/c"
# Erwartet: Verzeichnis $TMPDIR, $TMPDIR/sub = 2 Dirs; Dateien a,b,c = 3 Files → 5 gesamt

echo -e "${BOLD}[2] Zählt korrekt?${RESET}"; TT=$((TT+1))
OUT=$(cd "$TMPDIR" && bash "$PEER_DIR/count_files.sh" 2>/dev/null | tr -d ' ')
if [ "$OUT" = "5" ]; then echo -e "${GREEN}✓ 5${RESET}"; TP=$((TP+1)); else echo -e "${RED}✗ Erwartet 5, bekommen: $OUT${RESET}"; fi

echo "SCORE:$TP/$TT"
