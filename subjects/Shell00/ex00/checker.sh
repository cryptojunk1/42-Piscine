#!/bin/bash
# checker.sh – Shell00 ex00: z
PEER_DIR="$1"
RED='\033[0;31m'; GREEN='\033[0;32m'; BOLD='\033[1m'; RESET='\033[0m'
TP=0; TT=0

echo -e "${BOLD}[1] Datei 'z' vorhanden?${RESET}"
TT=$((TT+1))
if [ -f "$PEER_DIR/z" ]; then echo -e "${GREEN}✓${RESET}"; TP=$((TP+1)); else echo -e "${RED}✗ Datei fehlt${RESET}"; echo "SCORE:$TP/$TT"; exit 1; fi

echo -e "${BOLD}[2] cat z gibt 'Z' + Newline aus?${RESET}"
TT=$((TT+1))
OUT=$(cat "$PEER_DIR/z" 2>/dev/null)
if [ "$OUT" = "Z" ]; then echo -e "${GREEN}✓${RESET}"; TP=$((TP+1)); else echo -e "${RED}✗ Erwartet: 'Z', bekommen: '$OUT'${RESET}"; fi

echo "SCORE:$TP/$TT"
