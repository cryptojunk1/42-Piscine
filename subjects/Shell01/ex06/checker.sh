#!/bin/bash
PEER_DIR="$1"
RED='\033[0;31m'; GREEN='\033[0;32m'; BOLD='\033[1m'; RESET='\033[0m'
TP=0; TT=0

echo -e "${BOLD}[1] skip.sh vorhanden?${RESET}"; TT=$((TT+1))
[ -f "$PEER_DIR/skip.sh" ] && { echo -e "${GREEN}✓${RESET}"; TP=$((TP+1)); } || { echo -e "${RED}✗${RESET}"; echo "SCORE:0/3"; exit 1; }

echo -e "${BOLD}[2] Enthält ls -l?${RESET}"; TT=$((TT+1))
grep -q "ls -l" "$PEER_DIR/skip.sh" && { echo -e "${GREEN}✓${RESET}"; TP=$((TP+1)); } || echo -e "${RED}✗${RESET}"

echo -e "${BOLD}[3] Gibt jede zweite Zeile aus (ungerade Nummern)?${RESET}"; TT=$((TT+1))
TOTAL_LINES=$(ls -l | wc -l)
OUT_LINES=$(bash "$PEER_DIR/skip.sh" 2>/dev/null | wc -l)
EXPECTED_LINES=$(( (TOTAL_LINES + 1) / 2 ))
DIFF=$(( OUT_LINES - EXPECTED_LINES ))
[ "${DIFF#-}" -le 1 ] && { echo -e "${GREEN}✓ ~$OUT_LINES Zeilen (erwartet ~$EXPECTED_LINES)${RESET}"; TP=$((TP+1)); } \
  || echo -e "${RED}✗ $OUT_LINES Zeilen, erwartet ~$EXPECTED_LINES${RESET}"

echo "SCORE:$TP/$TT"
