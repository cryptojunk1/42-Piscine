#!/bin/bash
# checker.sh – Shell00 ex04: midLS
PEER_DIR="$1"
RED='\033[0;31m'; GREEN='\033[0;32m'; BOLD='\033[1m'; RESET='\033[0m'
TP=0; TT=0

echo -e "${BOLD}[1] Datei 'midLS' vorhanden?${RESET}"
TT=$((TT+1))
[ -f "$PEER_DIR/midLS" ] && { echo -e "${GREEN}✓${RESET}"; TP=$((TP+1)); } || { echo -e "${RED}✗${RESET}"; echo "SCORE:0/3"; exit 1; }

echo -e "${BOLD}[2] Enthält gültigen Befehl (ls)?${RESET}"
TT=$((TT+1))
CONTENT=$(cat "$PEER_DIR/midLS")
if echo "$CONTENT" | grep -q "ls"; then echo -e "${GREEN}✓ enthält ls${RESET}"; TP=$((TP+1)); else echo -e "${RED}✗ kein ls-Befehl${RESET}"; fi

echo -e "${BOLD}[3] Funktioniert in aktuellem Verzeichnis?${RESET}"
TT=$((TT+1))
TMPDIR=$(mktemp -d); trap "rm -rf $TMPDIR" EXIT
touch "$TMPDIR/file1" "$TMPDIR/file2"; mkdir "$TMPDIR/dir1"
OUT=$(cd "$TMPDIR" && eval "$(cat "$PEER_DIR/midLS")" 2>/dev/null)
if [ -n "$OUT" ]; then echo -e "${GREEN}✓ Ausgabe: $OUT${RESET}"; TP=$((TP+1)); else echo -e "${RED}✗ Kein Output${RESET}"; fi

echo "SCORE:$TP/$TT"
