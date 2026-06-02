#!/bin/bash
PEER_DIR="$1"
RED='\033[0;31m'; GREEN='\033[0;32m'; BOLD='\033[1m'; RESET='\033[0m'
TP=0; TT=0

echo -e "${BOLD}[1] find_sh.sh vorhanden?${RESET}"; TT=$((TT+1))
[ -f "$PEER_DIR/find_sh.sh" ] && { echo -e "${GREEN}✓${RESET}"; TP=$((TP+1)); } || { echo -e "${RED}✗${RESET}"; echo "SCORE:0/3"; exit 1; }

TMPDIR=$(mktemp -d); trap "rm -rf $TMPDIR" EXIT
mkdir -p "$TMPDIR/sub"; touch "$TMPDIR/test1.sh" "$TMPDIR/sub/test2.sh" "$TMPDIR/noext"

echo -e "${BOLD}[2] Findet .sh Dateien?${RESET}"; TT=$((TT+1))
OUT=$(cd "$TMPDIR" && bash "$PEER_DIR/find_sh.sh" 2>/dev/null)
if echo "$OUT" | grep -q "test1" && echo "$OUT" | grep -q "test2"; then echo -e "${GREEN}✓${RESET}"; TP=$((TP+1)); else echo -e "${RED}✗ Output: $OUT${RESET}"; fi

echo -e "${BOLD}[3] Ohne .sh-Endung?${RESET}"; TT=$((TT+1))
if ! echo "$OUT" | grep -q "\.sh"; then echo -e "${GREEN}✓${RESET}"; TP=$((TP+1)); else echo -e "${RED}✗ .sh noch in Output${RESET}"; fi

echo "SCORE:$TP/$TT"
